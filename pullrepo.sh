#!/usr/bin/env bash

REPO_URL_LST=()
REPO_NAME_LST=()
CLONE_COUNT=0

exit_on_SIGTERM () {
	echo "----"$CLONE_COUNT "repos cloned----"
	echo $((${#REPO_URL_LST[@]} - CLONE_COUNT)) "repos skipped."
	exit
}
exit_on_SIGQUIT () {
	echo "----"$CLONE_COUNT "repos cloned----"
	echo $((${#REPO_URL_LST[@]} - CLONE_COUNT)) "repos skipped."
	exit
}
exit_on_SIGINT () {
	echo "----"$CLONE_COUNT "repos cloned----"
	echo $((${#REPO_URL_LST[@]} - CLONE_COUNT)) "repos skipped."
	exit
}

trap exit_on_SIGTERM TERM
trap exit_on_SIGQUIT QUIT
trap exit_on_SIGINT INT

if [ "$1" ];
then
	echo "Retrieving repos..."
	curl -s "https://api.github.com/users/$1/repos" > /tmp/raw-repo
	jq '.[].clone_url' < /tmp/raw-repo > /tmp/clone_url

	echo "Calculating Number of repos..."
	for X in $(jq '.[].clone_url' < /tmp/raw-repo); do
		REPO_URL_LST+=("$X")
	done

	for Y in $(jq '.[].name' < /tmp/raw-repo); do
		REPO_NAME_LST+=("$Y")
	done

	echo ${#REPO_URL_LST[@]} "Repositories enumerated"
	sleep 1

	echo -e "--- REPO LIST ----\n"
	for IDX in "${!REPO_URL_LST[@]}"; do
		echo -n $((IDX + 1))
		echo -ne ':\t'
		echo "${REPO_URL_LST[$IDX]}" | cut -d "\"" -f 2
	done

	echo -e "\n--- END OF REPO LIST ----"
	echo "Select repos by number separated by a space character"
	echo -n "-> "
	read -ra USR_RQST_LST

	while true; do
		if [[ ${#USR_RQST_LST[@]} == 1 ]] && [[ ${USR_RQST_LST[0]} == 'a' ]]; then
			echo "Cloning ${#REPO_URL_LST[@]} repos..."
			xargs -I {} sh -c \
				"
					git clone -q {};
					echo -n '.';
				" < /tmp/clone_url
			sleep 0.5
			printf "\n---- %s repos cloned----" ${#REPO_URL_LST[@]}
			break
		else
			for IDX in "${!USR_RQST_LST[@]}"; do
				if ! [[ "${USR_RQST_LST[$IDX]}" =~ ^[0-9]+$ ]]; then
					USR_RQST_LST=()
					echo "Please enter only numbers"
					break
				fi
			done

			if [[ "${#USR_RQST_LST[@]}" -ne 0 ]]; then
				echo "Cloning ${#USR_RQST_LST[@]} repos..."
				for IDX in "${!USR_RQST_LST[@]}"; do
					echo "${REPO_URL_LST[$IDX]}" |
						cut -d "\"" -f 2 |
						xargs -I {} git clone -q {}
					echo "${REPO_NAME_LST[$IDX]} cloned"
				done
				break
			else
				echo -n "-> "
				read -ra USR_RQST_LST
			fi
		fi
	done
else
	1>&2 echo "Usage: ./pullrepo.sh <github_username> <PATH (optional)>"
fi
