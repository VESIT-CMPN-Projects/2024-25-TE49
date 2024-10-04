# ios/Flutter/podhelper.rb
def flutter_install_ios_engine_pod(flutter_application_path)
  pod 'Flutter', :path => File.join(flutter_application_path, 'Flutter')
end

def flutter_install_all_ios_pods(ios_application_path)
  flutter_install_ios_engine_pod(File.dirname(ios_application_path))
end