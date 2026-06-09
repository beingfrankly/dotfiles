return {
  cmd = {
    vim.fn.expand('~/.local/share/jls/dist/launch_system_java.sh'),
    'org.javacs.Main',
  },
  filetypes = { 'java' },
  root_markers = { 'pom.xml', 'build.gradle', 'build.gradle.kts', '.git' },
}
