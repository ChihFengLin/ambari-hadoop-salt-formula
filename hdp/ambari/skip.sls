skip_execute_formula:
  cmd.run:
    - name: echo "Skip executing formula because this host {{ grains.fqdn }} is not ambari server"
