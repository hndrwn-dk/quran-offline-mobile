# Quran Offline — make targets (requires bash)
# Usage: make setup | make run | make aab

.PHONY: help setup seed sync verify hooks run apk aab test qa

help:
	@bash scripts/qo.sh help

setup:
	@bash scripts/qo.sh setup

seed:
	@bash scripts/qo.sh seed

sync:
	@bash scripts/qo.sh sync

verify check:
	@bash scripts/qo.sh verify

hooks:
	@bash scripts/qo.sh hooks

run:
	@bash scripts/qo.sh run

apk:
	@bash scripts/qo.sh apk

aab appbundle:
	@bash scripts/qo.sh aab

test:
	@bash scripts/qo.sh test

qa:
	@bash scripts/qo.sh qa
