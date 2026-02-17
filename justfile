init host:
  @ansible-playbook main.yaml --limit {{host}} --tags init --ask-become-pass

update host:
  @ansible-playbook main.yaml --limit {{host}} --tags update --ask-become-pass

vault command:
  @ansible-vault {{command}} vars/vault.yaml
