require 'open3'
require 'open3_backport' if RUBY_VERSION < '1.9'

module Blacksmith
  class Git

    attr_accessor :path

    def initialize(path = ".")
      @path = File.expand_path(path)
    end

    def tag!(version)
      exec_git "tag v#{version}"
    end

    def commit_modulefile!
      s = exec_git "add Modulefile"
      s += exec_git "commit -m '[blacksmith] Bump version'"
      s
    end

    def push!
      s = exec_git "push"
      s += exec_git "push --tags"
      s
    end

    def git_cmd_with_path(cmd)
      "git --git-dir=#{File.join(path, '.git')} --work-tree=#{path} #{cmd}"
    end

    def exec_git(cmd)
      out = ""
      err = ""
      exit_status = nil
      new_cmd = git_cmd_with_path(cmd)
      # wait_thr is nil in JRuby < 1.7.5 see http://jira.codehaus.org/browse/JRUBY-6409
      Open3.popen3(new_cmd) do |stdin, stdout, stderr, wait_thr|
        out = stdout.read
        err = stderr.read
        exit_status = wait_thr.nil? ? nil : wait_thr.value
      end
      if exit_status.nil?
        raise Blacksmith::Error, err unless err.empty?
      elsif !exit_status.success?
        raise Blacksmith::Error, err.empty? ? "Command #{new_cmd} failed with exit status #{exit_status}" : err
      end
      return out
    end
  end
end
