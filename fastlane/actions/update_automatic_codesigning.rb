module Fastlane
  module Actions
    class UpdateAutomaticCodesigningAction < Action
      def self.run(params)
        path = params[:path]
        path = File.join(File.expand_path(path), "project.pbxproj")
        UI.user_error!("Could not find path to project config '#{path}'. Pass the path to your project (not workspace)!") unless File.exist?(path)
        UI.message("Updating the Automatic Codesigning flag to #{params[:use_automatic_signing] ? 'enabled' : 'disabled'} for the given project '#{path}'")
        p = File.read(path)
        File.write(path, p.gsub(/ProvisioningStyle = .*;/, "ProvisioningStyle = #{params[:use_automatic_signing] ? 'Automatic' : 'Manual'};"))
        UI.success("Successfully updated project settings to use ProvisioningStyle '#{params[:use_automatic_signing] ? 'Automatic' : 'Manual'}'")
      
        pods_project = Xcodeproj::Project.open(Dir["Pods/Pods.xcodeproj"].first)

        targets_ids = []
        pods_project.root_object.targets.each { |target|
          puts(target)
          targets_ids.push(target.uuid)
        }
        puts("target_ids = #{targets_ids}")

        pods_project_attrs = pods_project.root_object.attributes
        target_attributes = pods_project_attrs['TargetAttributes']
        if !target_attributes 
          pods_project_attrs['TargetAttributes'] = {}
        end
        puts("pods_project_attrs = #{pods_project_attrs}")
        targets_ids.each { |target_id|
          pods_project_attrs['TargetAttributes'][target_id] = {
            'ProvisioningStyle' => 'Manual'
          }
        }
        puts("pods_project_attrs = #{pods_project_attrs}")
        pods_project.root_object.attributes = pods_project_attrs
        puts("pods_project.root_object.attributes = #{pods_project.root_object.attributes}")

        pods_project.root_object.targets.each { |target|
          target.build_configurations.each { |config|
            config.build_settings['SWIFT_VERSION'] = '2.3'
          }
        }
        pods_project.save
      end

      def self.description
        "Updates the Xcode 8 Automatic Codesigning Flag"
      end

      def self.details
        "Updates the Xcode 8 Automatic Codesigning Flag of all targets in the project"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :path,
                                       env_name: "FL_PROJECT_SIGNING_PROJECT_PATH",
                                       description: "Path to your Xcode project",
                                       verify_block: proc do |value|
                                         UI.user_error!("Path is invalid") unless File.exist?(File.expand_path(value))
                                       end),
          FastlaneCore::ConfigItem.new(key: :use_automatic_signing,
                                       env_name: "FL_PROJECT_USE_AUTOMATIC_SIGNING",
                                       description: "Defines if project should use automatic signing",
                                       default_value: false)
        ]
      end

      def self.output
      end

      def self.return_value
      end

      def self.authors
        ["mathiasAichinger"]
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
    end
  end
end