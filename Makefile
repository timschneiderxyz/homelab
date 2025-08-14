.PHONY: init
init:
	@ansible-playbook main.yaml --limit $(filter-out $@,$(MAKECMDGOALS)) --tags init --ask-become-pass||:

.PHONY: update
update:
	@ansible-playbook main.yaml --limit $(filter-out $@,$(MAKECMDGOALS)) --tags update --ask-become-pass||:

.PHONY: vault
vault:
	@ansible-vault $(filter-out $@,$(MAKECMDGOALS)) vars/vault.yaml||:

%:
	@:
