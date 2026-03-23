#!/bin/bash
source "$HOME/dotfiles/config/tmux/chip.sh"

kube_context="---"
kube_namespace="default"
if current_context=$(kubectl config current-context 2>/dev/null); then
	if [[ "$current_context" == *"_"* ]]; then
		kube_context="${current_context##*_}"
	else
		kube_context="$current_context"
	fi
	kube_namespace=$(kubectl config view --raw -o jsonpath='{.contexts[?(@.name=="'"$current_context"'")].context.namespace}' 2>/dev/null)
	[[ -z "$kube_namespace" ]] && kube_namespace="default"
fi

chip "⎈" "${kube_context}:${kube_namespace}" "$CLR_TEAL"
