.PHONY: run
run:
	@ansible-playbook main.yaml --limit $(filter-out $@,$(MAKECMDGOALS)) --tags run --ask-become-pass||:

.PHONY: update
update:
	@ansible-playbook main.yaml --limit $(filter-out $@,$(MAKECMDGOALS)) --tags update --ask-become-pass||:

.PHONY: copysshkey
copysshkey:
	@ssh-copy-id -i ~/.ssh/id_ed25519.pub $(filter-out $@,$(MAKECMDGOALS))||:

.PHONY: vault
vault:
	@ansible-vault $(filter-out $@,$(MAKECMDGOALS)) vars/vault.yaml||:

.PHONY: gitvaulthook
gitvaulthook:
	@chmod u+x ./git-vault-hook.sh||:
	@./git-vault-hook.sh||:

%:
	@:
