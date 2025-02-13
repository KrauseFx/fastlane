require 'fastlane_core'

module Supply
  # rubocop:disable Metrics/ClassLength
  class Uploader
    UploadJob = Struct.new(:language, :version_code, :release_notes_queue)

    def perform_upload
      FastlaneCore::PrintTable.print_values(config: Supply.config, hide_keys: [:issuer], mask_keys: [:json_key_data], title: "Summary for supply #{Fastlane::VERSION}")

      client.begin_edit(package_name: Supply.config[:package_name])

      verify_config!

      apk_version_codes = []
      apk_version_codes.concat(upload_apks) unless Supply.config[:skip_upload_apk]
      apk_version_codes.concat(upload_bundles) unless Supply.config[:skip_upload_aab]
      upload_mapping(apk_version_codes)

      track_to_update = Supply.config[:track]

      apk_version_codes.concat(Supply.config[:version_codes_to_retain]) if Supply.config[:version_codes_to_retain]

      if !apk_version_codes.empty?
        # Only update tracks if we have version codes
        # update_track handle setting rollout if needed
        # Updating a track with empty version codes can completely clear out a track
        update_track(apk_version_codes)
      else
        # Only promote or rollout if we don't have version codes
        if Supply.config[:track_promote_to]
          track_to_update = Supply.config[:track_promote_to]
          promote_track
        elsif !Supply.config[:rollout].nil? && Supply.config[:track].to_s != ""
          update_rollout
        end
      end

      perform_upload_meta(apk_version_codes, track_to_update)

      if Supply.config[:validate_only]
        UI.message("Validating all changes with Google Play...")
        client.validate_current_edit!
        UI.success("Successfully validated the upload to Google Play")
      else
        UI.message("Uploading all changes to Google Play...")
        client.commit_current_edit!
        UI.success("Successfully finished the upload to Google Play")
      end
    end

    def perform_upload_to_internal_app_sharing
      download_urls = []

      package_name = Supply.config[:package_name]

      apk_paths = [Supply.config[:apk]] unless (apk_paths = Supply.config[:apk_paths])
      apk_paths.compact!
      apk_paths.each do |apk_path|
        download_url = client.upload_apk_to_internal_app_sharing(package_name, apk_path)
        download_urls << download_url
        UI.success("Successfully uploaded APK to Internal App Sharing URL: #{download_url}")
      end

      aab_paths = [Supply.config[:aab]] unless (aab_paths = Supply.config[:aab_paths])
      aab_paths.compact!
      aab_paths.each do |aab_path|
        download_url = client.upload_bundle_to_internal_app_sharing(package_name, aab_path)
        download_urls << download_url
        UI.success("Successfully uploaded AAB to Internal App Sharing URL: #{download_url}")
      end

      if download_urls.count == 1
        return download_urls.first
      else
        return download_urls
      end
    end

    def perform_upload_meta(version_codes, track_name)
      if (!Supply.config[:skip_upload_metadata] || !Supply.config[:skip_upload_images] || !Supply.config[:skip_upload_changelogs] || !Supply.config[:skip_upload_screenshots]) && metadata_path
        # Use version code from config if version codes is empty and no nil or empty string
        version_codes = [Supply.config[:version_code]] if version_codes.empty?
        version_codes = version_codes.reject do |version_code|
          version_codes.to_s == ""
        end

        version_codes.each do |version_code|
          UI.user_error!("Could not find folder #{metadata_path}") unless File.directory?(metadata_path)

          track, release = fetch_track_and_release!(track_name, version_code)
          UI.user_error!("Unable to find the requested track - '#{Supply.config[:track]}'") unless track
          UI.user_error!("Could not find release for version code '#{version_code}' to update changelog") unless release

          release_notes_queue = Queue.new
          upload_worker = create_meta_upload_worker
          upload_worker.batch_enqueue(
            # skip . or .. or hidden folders
            all_languages.reject { |lang| lang.start_with?('.') }.map { |lang| UploadJob.new(lang, version_code, release_notes_queue) }
          )
          upload_worker.start

          release_notes = Array.new(release_notes_queue.size) { release_notes_queue.pop } # Queue to Array
          upload_changelogs(release_notes, release, track, track_name) unless release_notes.empty?
        end
      end
    end

    def fetch_track_and_release!(track, version_code, statuses = nil)
      tracks = client.tracks(track)
      return nil, nil if tracks.empty?

      track = tracks.first
      releases = track.releases

      releases = releases.select { |r| statuses.include?(r.status) } unless statuses.nil? || statuses.empty?
      releases = releases.select { |r| (r.version_codes || []).map(&:to_s).include?(version_code.to_s) } if version_code

      if releases.size > 1
        UI.user_error!("More than one release found in this track. Please specify with the :version_code option to select a release.")
      end

      return track, releases.first
    end

    def update_rollout
      track, release = fetch_track_and_release!(Supply.config[:track], Supply.config[:version_code], [Supply::ReleaseStatus::IN_PROGRESS, Supply::ReleaseStatus::DRAFT])
      UI.user_error!("Unable to find the requested track - '#{Supply.config[:track]}'") unless track
      UI.user_error!("Unable to find the requested release on track - '#{Supply.config[:track]}'") unless release

      version_code = release.version_codes.max

      UI.message("Updating #{version_code}'s rollout to '#{Supply.config[:rollout]}' on track '#{Supply.config[:track]}'...")

      if track && release
        completed = Supply.config[:rollout].to_f == 1
        release.user_fraction = completed ? nil : Supply.config[:rollout]
        if Supply.config[:release_status]
          release.status = Supply.config[:release_status]
        else
          release.status = completed ? Supply::ReleaseStatus::COMPLETED : Supply::ReleaseStatus::IN_PROGRESS
        end

        # It's okay to set releases to an array containing the newest release
        # Google Play will keep previous releases there untouched
        track.releases = [release]
      else
        UI.user_error!("Unable to find version to rollout in track '#{Supply.config[:track]}'")
      end

      client.update_track(Supply.config[:track], track)
    end

    def verify_config!
      unless metadata_path || Supply.config[:apk] || Supply.config[:apk_paths] || Supply.config[:aab] || Supply.config[:aab_paths] || (Supply.config[:track] && Supply.config[:track_promote_to]) || (Supply.config[:track] && Supply.config[:rollout])
        UI.user_error!("No local metadata, apks, aab, or track to promote were found, make sure to run `fastlane supply init` to setup supply")
      end

      # Can't upload both at apk and aab at same time
      # Need to error out users when there both apks and aabs are detected
      apk_paths = [Supply.config[:apk], Supply.config[:apk_paths]].flatten.compact
      could_upload_apk = !apk_paths.empty? && !Supply.config[:skip_upload_apk]
      could_upload_aab = Supply.config[:aab] && !Supply.config[:skip_upload_aab]
      if could_upload_apk && could_upload_aab
        UI.user_error!("Cannot provide both apk(s) and aab - use `skip_upload_apk`, `skip_upload_aab`, or  make sure to remove any existing .apk or .aab files that are no longer needed")
      end

      if Supply.config[:release_status] == Supply::ReleaseStatus::DRAFT && Supply.config[:rollout]
        UI.user_error!(%(Cannot specify rollout percentage when the release status is set to 'draft'))
      end

      if Supply.config[:track_promote_release_status] == Supply::ReleaseStatus::DRAFT && Supply.config[:rollout]
        UI.user_error!(%(Cannot specify rollout percentage when the track promote release status is set to 'draft'))
      end

      unless Supply.config[:version_codes_to_retain].nil?
        Supply.config[:version_codes_to_retain] = Supply.config[:version_codes_to_retain].map(&:to_i)
      end
    end

    def promote_track
      track_from = client.tracks(Supply.config[:track]).first
      unless track_from
        UI.user_error!("Cannot promote from track '#{Supply.config[:track]}' - track doesn't exist")
      end

      releases = track_from.releases

      if Supply.config[:track_promote_force]
        if Supply.config[:version_name].nil?
          UI.user_error!("To force promote a :version_code, it is mandatory to enter the :version_name")
        end

        releases.first.name = Supply.config[:version_name]
        releases.first.version_codes = [Supply.config[:version_code].to_s]
      end

      if Supply.config[:version_code].to_s != ""
        releases = releases.select do |release|
          release.version_codes.include?(Supply.config[:version_code].to_s)
        end
      else
        releases = releases.select do |release|
          release.status == Supply.config[:release_status]
        end
      end

      if releases.size == 0
        UI.user_error!("Track '#{Supply.config[:track]}' doesn't have any releases")
      elsif releases.size > 1
        UI.user_error!("Track '#{Supply.config[:track]}' has more than one release - use :version_code to filter the release to promote")
      end

      release = releases.first
      track_to = client.tracks(Supply.config[:track_promote_to]).first

      rollout = (Supply.config[:rollout] || 0).to_f
      if rollout > 0 && rollout < 1
        release.status = Supply::ReleaseStatus::IN_PROGRESS
        release.user_fraction = rollout
      else
        release.status = Supply.config[:track_promote_release_status]
        release.user_fraction = nil
      end

      if track_to
        # It's okay to set releases to an array containing the newest release
        # Google Play will keep previous releases there this release is a partial rollout
        track_to.releases = [release]
      else
        track_to = AndroidPublisher::Track.new(
          track: Supply.config[:track_promote_to],
          releases: [release]
        )
      end

      client.update_track(Supply.config[:track_promote_to], track_to)
    end

    def upload_changelog(language, version_code)
      UI.user_error!("Cannot find changelog because no version code given - please specify :version_code") unless version_code

      path = File.join(Supply.config[:metadata_path], language, Supply::CHANGELOGS_FOLDER_NAME, "#{version_code}.txt")
      changelog_text = ''
      if File.exist?(path)
        UI.message("Updating changelog for '#{version_code}' and language '#{language}'...")
        changelog_text = File.read(path, encoding: 'UTF-8')
      else
        default_changelog_path = File.join(Supply.config[:metadata_path], language, Supply::CHANGELOGS_FOLDER_NAME, "default.txt")
        if File.exist?(default_changelog_path)
          UI.message("Updating changelog for '#{version_code}' and language '#{language}' to default changelog...")
          changelog_text = File.read(default_changelog_path, encoding: 'UTF-8')
        else
          UI.message("Could not find changelog for '#{version_code}' and language '#{language}' at path #{path}...")
        end
      end

      AndroidPublisher::LocalizedText.new(
        language: language,
        text: changelog_text
      )
    end

    def upload_changelogs(release_notes, release, track, track_name)
      release.release_notes = release_notes
      client.upload_changelogs(track, track_name)
    end

    def upload_metadata(language, listing)
      Supply::AVAILABLE_METADATA_FIELDS.each do |key|
        path = File.join(metadata_path, language, "#{key}.txt")
        listing.send("#{key}=".to_sym, File.read(path, encoding: 'UTF-8')) if File.exist?(path)
      end
      begin
        listing.save
      rescue Encoding::InvalidByteSequenceError => ex
        message = (ex.message || '').capitalize
        UI.user_error!("Metadata must be UTF-8 encoded. #{message}")
      end
    end

    def upload_images(language)
      Supply::IMAGES_TYPES.each do |image_type|
        search = File.join(metadata_path, language, Supply::IMAGES_FOLDER_NAME, image_type) + ".#{IMAGE_FILE_EXTENSIONS}"
        path = Dir.glob(search, File::FNM_CASEFOLD).last
        next unless path

        if Supply.config[:sync_image_upload]
          UI.message("🔍 Checking #{image_type} checksum...")
          existing_images = client.fetch_images(image_type: image_type, language: language)
          sha256 = Digest::SHA256.file(path).hexdigest
          if existing_images.map(&:sha256).include?(sha256)
            UI.message("🟰 Skipping upload of screenshot #{path} as remote sha256 matches.")
            next
          end
        end

        UI.message("⬆️ Uploading image file #{path}...")
        client.upload_image(image_path: File.expand_path(path),
                            image_type: image_type,
                              language: language)
      end
    end

    def upload_screenshots(language)
      Supply::SCREENSHOT_TYPES.each do |screenshot_type|
        search = File.join(metadata_path, language, Supply::IMAGES_FOLDER_NAME, screenshot_type, "*.#{IMAGE_FILE_EXTENSIONS}")
        paths = Dir.glob(search, File::FNM_CASEFOLD).sort
        next unless paths.count > 0

        if Supply.config[:sync_image_upload]
          UI.message("🔍 Checking #{screenshot_type} checksums...")
          existing_images = client.fetch_images(image_type: screenshot_type, language: language)
          # Don't keep images that either don't exist locally, or that are out of order compared to the `paths` to upload
          first_path_checksum = Digest::SHA256.file(paths.first).hexdigest
          existing_images.each do |image|
            if image.sha256 == first_path_checksum
              UI.message("🟰 Skipping upload of screenshot #{paths.first} as remote sha256 matches.")
              paths.shift # Remove first path from the list of paths to be uploaded
              first_path_checksum = paths.empty? ? nil : Digest::SHA256.file(paths.first).hexdigest
            else
              UI.message("🚮 Deleting #{language} screenshot id ##{image.id} as it does not exist locally or is out of order...")
              client.clear_screenshot(image_type: screenshot_type, language: language, image_id: image.id)
            end
          end
        else
          client.clear_screenshots(image_type: screenshot_type, language: language)
        end

        paths.each do |path|
          UI.message("⬆️  Uploading screenshot #{path}...")
          client.upload_image(image_path: File.expand_path(path),
                              image_type: screenshot_type,
                                language: language)
        end
      end
    end

    def upload_apks
      apk_paths = [Supply.config[:apk]] unless (apk_paths = Supply.config[:apk_paths])
      apk_paths.compact!

      apk_version_codes = []

      apk_paths.each do |apk_path|
        apk_version_codes.push(upload_binary_data(apk_path))
      end

      return apk_version_codes
    end

    def upload_mapping(apk_version_codes)
      mapping_paths = [Supply.config[:mapping]] unless (mapping_paths = Supply.config[:mapping_paths])
      mapping_paths.product(apk_version_codes).each do |mapping_path, version_code|
        if mapping_path
          UI.message("Preparing mapping at path '#{mapping_path}', version code #{version_code} for upload...")
          client.upload_mapping(mapping_path, version_code)
        end
      end
    end

    def upload_bundles
      aab_paths = [Supply.config[:aab]] unless (aab_paths = Supply.config[:aab_paths])
      return [] unless aab_paths
      aab_paths.compact!

      aab_version_codes = []

      aab_paths.each do |aab_path|
        UI.message("Preparing aab at path '#{aab_path}' for upload...")
        bundle_version_code = client.upload_bundle(aab_path)
        aab_version_codes.push(bundle_version_code)
      end

      return aab_version_codes
    end

    private

    ##
    # Upload binary apk and obb and corresponding change logs with client
    #
    # @param [String] apk_path
    #    Path of the apk file to upload.
    #
    # @return [Integer] The apk version code returned after uploading, or nil if there was a problem
    def upload_binary_data(apk_path)
      apk_version_code = nil

      if apk_path
        UI.message("Preparing apk at path '#{apk_path}' for upload...")
        apk_version_code = client.upload_apk(apk_path)
        UI.user_error!("Could not upload #{apk_path}") unless apk_version_code

        if Supply.config[:obb_main_references_version] && Supply.config[:obb_main_file_size]
          update_obb(apk_version_code,
                     'main',
                     Supply.config[:obb_main_references_version],
                     Supply.config[:obb_main_file_size])
        end

        if Supply.config[:obb_patch_references_version] && Supply.config[:obb_patch_file_size]
          update_obb(apk_version_code,
                     'patch',
                     Supply.config[:obb_patch_references_version],
                     Supply.config[:obb_patch_file_size])
        end

        upload_obbs(apk_path, apk_version_code)
      else
        UI.message("No apk file found, you can pass the path to your apk using the `apk` option")
      end

      UI.message("\tVersion Code: #{apk_version_code}")
      apk_version_code
    end

    def update_obb(apk_version_code, expansion_file_type, references_version, file_size)
      UI.message("Updating '#{expansion_file_type}' expansion file from version '#{references_version}'...")
      client.update_obb(apk_version_code,
                        expansion_file_type,
                        references_version,
                        file_size)
    end

    def update_track(apk_version_codes)
      return if apk_version_codes.empty?

      UI.message("Updating track '#{Supply.config[:track]}'...")

      track_release = AndroidPublisher::TrackRelease.new(
        name: Supply.config[:version_name],
        status: Supply.config[:release_status],
        version_codes: apk_version_codes
      )

      if Supply.config[:rollout]
        rollout = Supply.config[:rollout].to_f
        if rollout > 0 && rollout < 1
          track_release.status = Supply::ReleaseStatus::IN_PROGRESS
          track_release.user_fraction = rollout
        end
      end

      if Supply.config[:in_app_update_priority]
        track_release.in_app_update_priority = Supply.config[:in_app_update_priority].to_i
      end

      tracks = client.tracks(Supply.config[:track])
      track = tracks.first
      if track
        # It's okay to set releases to an array containing the newest release
        # Google Play will keep previous releases there this release is a partial rollout
        track.releases = [track_release]
      else
        track = AndroidPublisher::Track.new(
          track: Supply.config[:track],
          releases: [track_release]
        )
      end

      client.update_track(Supply.config[:track], track)
    end

    # returns only language directories from metadata_path
    def all_languages
      Dir.entries(metadata_path)
         .select { |f| File.directory?(File.join(metadata_path, f)) }
         .reject { |f| f.start_with?('.') }
         .sort { |x, y| x <=> y }
    end

    def client
      @client ||= Client.make_from_config
    end

    def metadata_path
      Supply.config[:metadata_path]
    end

    # searches for obbs in the directory where the apk is located and
    # upload at most one main and one patch file. Do nothing if it finds
    # more than one of either of them.
    def upload_obbs(apk_path, apk_version_code)
      expansion_paths = find_obbs(apk_path)
      ['main', 'patch'].each do |type|
        if expansion_paths[type]
          upload_obb(expansion_paths[type], type, apk_version_code)
        end
      end
    end

    # @return a map of the obb paths for that apk
    # keyed by their detected expansion file type
    # E.g.
    # { 'main' => 'path/to/main.obb', 'patch' => 'path/to/patch.obb' }
    def find_obbs(apk_path)
      search = File.join(File.dirname(apk_path), '*.obb')
      paths = Dir.glob(search, File::FNM_CASEFOLD)
      expansion_paths = {}
      paths.each do |path|
        type = obb_expansion_file_type(path)
        next unless type
        if expansion_paths[type]
          UI.important("Can only upload one '#{type}' apk expansion. Skipping obb upload entirely.")
          UI.important("If you'd like this to work differently, please submit an issue.")
          return {}
        end
        expansion_paths[type] = path
      end
      expansion_paths
    end

    def upload_obb(obb_path, expansion_file_type, apk_version_code)
      UI.message("Uploading obb file #{obb_path}...")
      client.upload_obb(obb_file_path: obb_path,
                        apk_version_code: apk_version_code,
                        expansion_file_type: expansion_file_type)
    end

    def obb_expansion_file_type(obb_file_path)
      filename = File.basename(obb_file_path, ".obb")
      if filename.include?('main')
        'main'
      elsif filename.include?('patch')
        'patch'
      end
    end

    def create_meta_upload_worker
      FastlaneCore::QueueWorker.new do |job|
        UI.message("Preparing uploads for language '#{job.language}'...")
        start_time = Time.now
        listing = client.listing_for_language(job.language)
        upload_metadata(job.language, listing) unless Supply.config[:skip_upload_metadata]
        upload_images(job.language) unless Supply.config[:skip_upload_images]
        upload_screenshots(job.language) unless Supply.config[:skip_upload_screenshots]
        job.release_notes_queue << upload_changelog(job.language, job.version_code) unless Supply.config[:skip_upload_changelogs]
        UI.message("Uploaded all items for language '#{job.language}'... (#{Time.now - start_time} secs)")
      rescue => error
        UI.abort_with_message!("#{job.language} - #{error}")
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end
