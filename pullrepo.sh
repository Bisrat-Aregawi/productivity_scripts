#!/usr/bin/env bash

REPO_URL_LIST=()
REPO_NAME_LIST=()
ELEM=""
CLONE_COUNT=0

exit_on_SIGTERM () {
	echo "----"$CLONE_COUNT "repos cloned----"
	echo $((${#REPO_URL_LIST[@]} - $CLONE_COUNT)) "repos skipped."
	exit
}
exit_on_SIGQUIT () {
	echo "----"$CLONE_COUNT "repos cloned----"
	echo $((${#REPO_URL_LIST[@]} - $CLONE_COUNT)) "repos skipped."
	exit
}
exit_on_SIGINT () {
	echo "----"$CLONE_COUNT "repos cloned----"
	echo $((${#REPO_URL_LIST[@]} - $CLONE_COUNT)) "repos skipped."
	exit
}

trap exit_on_SIGTERM TERM
trap exit_on_SIGQUIT QUIT
trap exit_on_SIGINT INT

if [ $1 ];
then
	echo "Retrieving repos..."
	curl -s https://api.github.com/users/$1/repos > /tmp/temp

	echo "Calculating Number of repos..."
	for X in $(cat /tmp/temp | jq '.[].clone_url'); do
		REPO_URL_LIST+=($X)
	done
	for Y in $(cat /tmp/temp | jq '.[].name'); do
		REPO_NAME_LIST+=($Y)
	done
	echo ${#REPO_URL_LIST[@]} "Repositories enumerated"
	sleep 1

	echo -e "--- REPO LIST ----\n"
	for IDX in ${!REPO_URL_LIST[@]}; do
		echo -n $(($IDX + 1))
		echo -ne ':\t'
		echo ${REPO_URL_LIST[$IDX]} | cut -d "\"" -f 2
	done
	echo -e "\n--- END OF REPO LIST ----"

	echo "Cloning ${#REPO_URL_LIST[@]} repos..."
	for IDX in ${!REPO_URL_LIST[@]}; do
		if [ $2 ];
		then
			path=${REPO_NAME_LIST[IDX]} |
				cut -d "\"" -f 2 |
				xargs -I {} echo $2/{}
			echo ${REPO_URL_LIST[$IDX]} |
				cut -d "\"" -f 2 |
				xargs -I {} git clone -q {} $path
		fi
		echo "$(($IDX + 1)) (${REPO_NAME_LIST[IDX]}) cloned " 
		CLONE_COUNT=$((IDX+1))
	done
	echo "----"$CLONE_COUNT "repos cloned----"
else
	1>&2 echo "Usage: ./pullrepo.sh <github_username> <PATH (optional)>"
fi
