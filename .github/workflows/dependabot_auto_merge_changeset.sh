pr_number=$(gh pr view --json number --jq '.number')
changeset_filename=".changeset/dependabot-$pr_number.md"

if [ -f $changeset_filename ]; then
  echo "Changeset $changeset_filename already exists, skipping"
  exit 0
fi

package_names=()
for file in $(gh pr diff --name-only)
do
  if [[ "$file" =~ ^packages\/.*\/package.json$ ]]; then
    echo "Found changed package.json: $file"

    package_name=$(cat $file | jq -r '.name')
    package_names+=("$package_name")
  fi
done

package_updates=""
for package_name in "${package_names[@]}"
do
  package_updates="$package_updates'$package_name': patch\n"
done

dependencies='`'$(sed "s/,/\`, \`/g" <<< "$DEPENDENCIES")'`'
echo "Creating changeset: $changeset_filename"
echo "---
$package_updates---

Updated $dependencies dependencies
" > $changeset_filename

echo "Configuring git"
git config user.name github-actions
git config user.email github-actions@github.com

echo "Adding changeset to git"
git checkout $BRANCH
git add $changeset_filename
git commit -m "[dependabot skip] Adding changeset for dependabot update"
git push
