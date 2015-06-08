Project: openrov-rov-suite

This project serves as a wrapper around all of the subcomponets that make up the software that runs on the OpenROV.

There are three deployment branches for this project:

* master: development branch  [![Build Status](https://travis-ci.org/OpenROV/openrov-rov-suite.svg?branch=master)](https://travis-ci.org/OpenROV/openrov-rov-suite)
* pre-release: release canidates for the next release [![Build Status](https://travis-ci.org/OpenROV/openrov-rov-suite.svg?branch=pre-release)](https://travis-ci.org/OpenROV/openrov-rov-suite)
* stable: released versions of the software [![Build Status](https://travis-ci.org/OpenROV/openrov-rov-suite.svg?branch=stable)](https://travis-ci.org/OpenROV/openrov-rov-suite)

For submitting issues use the primary software repository: https://github.com/OpenROV/openrov-software/issues

In the master branch, the manifest (file + version) of dependent projects is generated from scratch each time getting the most recent versions of all of the dependencies.  In the future we may add an option to include a version number in the inventory file that defines what is in the manifest to effectively "pin" a dependecy at a particular version number.

When moving from master to the pre-release branch, we checkin an updated version of the manifest_release file.  This contains the version number of each packages associated with the release.  If we make patches to the dependent  projects we must manually update the version number.

The package.json file keeps the primary version number for the suite.  When we move the next release to the pre-release branch, we also increment the version number in master to signal that master is now on the next point release.

The debian package for the suite is built in the travis-ci build servers and automatically pushed to the OpenROV debian repository.

On an openrov image, you can manually update with the following commands:

```    
sudo apt-get update
sudo apt-get install openrov-rov-suite
```
