release_type:
	bundle exec bump $(type) --tag --replace-in lib/rralph.rb
	git push --follow-tags

hotfix:
	$(MAKE) release_type type=patch

minor:
	$(MAKE) release_type type=minor

major:
	$(MAKE) release_type type=major
