class Pj < Formula
  desc "Fast project jumper - quickly switch between git project directories with fuzzy search"
  homepage "https://github.com/jalon-dg/pj"
  url "https://github.com/jalon-dg/pj.git"
  version "1.0.0"
  license "MIT"

  head "https://github.com/jalon-dg/pj.git", branch: "main"

  def install
    # 安装 bash/zsh 版本
    bin.install "pj.sh" => "pj"

    # 安装 PowerShell 版本
    (prefix/"powershell").install "pj.ps1"
  end

  def post_install
    # 添加 shell 配置
    shell_config = nil
    if ENV["SHELL"]&.include?("zsh")
      shell_config = "#{Dir.home}/.zshrc"
    elsif ENV["SHELL"]&.include?("bash")
      shell_config = "#{Dir.home}/.bashrc"
      shell_config = "#{Dir.home}/.bash_profile" if OS.mac?
    end

    if shell_config && File.exist?(shell_config)
      source_line = "source #{opt_bin}/pj"
      unless File.read(shell_config).include?(source_line)
        File.open(shell_config, "a") do |f|
          f.puts ""
          f.puts "# pj - 快速项目跳转工具"
          f.puts source_line
        end
        puts "✅ 已添加到 #{shell_config}"
        puts "   请执行: source #{shell_config}"
      end
    end

    puts ""
    puts "✅ pj 安装完成！"
    puts ""
    puts "使用方式:"
    puts "  pj list                # 列出所有项目"
    puts "  pj -p <关键词>         # 模糊搜索并跳转"
    puts "  pj <项目名>            # 精确匹配跳转"
    puts "  pj adddir <路径>       # 添加监控目录"
    puts "  pj refresh             # 刷新缓存"
  end

  def caveats
    <<~EOS
      pj 已安装！

      如果在安装过程中没有自动添加 shell 配置，请手动添加以下行：

      bash:
        echo 'source #{opt_bin}/pj' >> ~/.bashrc

      zsh:
        echo 'source #{opt_bin}/pj' >> ~/.zshrc

      PowerShell (Windows):
        Add-Content -Path $PROFILE -Value ". '#{prefix}/powershell/pj.ps1'"

      使用前请重新加载 shell 配置:
        source ~/.bashrc   # 或
        source ~/.zshrc    # 或
        . $PROFILE
    EOS
  end
end