# centos-base
Centos image with tools installed. Two docker images are created from this project. The first is a Centos7 image with 
frequently used tools and utilities. The second image is based off the first with the addition of headless OpenJDK7.

# Releasing
Use git flow to release a version to the master branch. A jenkins job can be triggered manually to build and publish the
images to docker hub.  During the git flow release process, update the version in the makefile by removing the `dev`
suffix and then increment the version number in the develop branch.

## Release Steps

1. Check out the master branch and make sure to have latest master.
  * `git checkout master` 
  * `git pull origin master`

2. Check out the develop branch.
  * `git checkout develop`
  * `git pull origin develop`

3. Start release of next version. The version is usually the version in the makefile minus the `dev` suffix.  e.g., if the version 
  in develop is `1.0.3-dev` and in master `1.0.2`, then the 
  `<release_name>` will be the new version in master, i.e. `1.0.3`.
  *  `git flow release start <release_name>`

4. Update the `VERSION` variable in the make file.

5. run `make` to make sure everything builds properly.

6. Commit and tag everything, don't push.
  * `git commit....`
  * `git flow release finish <release_name>`
  * `git push origin --tags`

7. You will be on the develop branch again. While on develop branch increment develop branch to the next dev version.

8. Check in develop version bump and push.
  * `git commit...`
  * `git push`

9. Push the master branch which should have the new released version.
  * `git checkout master`
  * `git push`
  
10. Have someone manually kick off the jenkins job to build and publish images.


