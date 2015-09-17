require_relative '../util'

module VagrantPlugins
  module ProxyConf
    module Cap
      module Debian
        # Capability for docker proxy configuration
        module DockerProxyConf
          CONFIG_PATH = '/etc/default/docker'
          # @return [String, false] the path to docker or `false` if not found
          def self.docker_proxy_conf(machine)
            return false unless Util.which(machine, 'docker')
            return CONFIG_PATH unless Util.which(machine, 'systemctl')

            machine.communicate.tap do |comm|
              src_file = '/lib/systemd/system/docker.service'
              dst_file = '/etc/systemd/system/docker.service'
              tmp_file = '/tmp/docker.service'
              env_file = 'EnvironmentFile=-\/etc\/default\/docker'
              comm.sudo("sed -e 's/\\[Service\\]/[Service]\\n#{env_file}/g' #{src_file} > #{tmp_file}")
              unless comm.test("diff #{tmp_file} #{dst_file}")
                # update config and restart docker when config changed
                comm.sudo("mv -f #{tmp_file} #{dst_file}")
                comm.sudo('systemctl daemon-reload')
              end
              comm.sudo("rm -f #{tmp_file}")
            end
            CONFIG_PATH
          end
        end
      end
    end
  end
end
