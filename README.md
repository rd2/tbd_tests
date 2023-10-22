# Testing TBD  

_Thermal Bridging & Derating_ (or [TBD](https://github.com/rd2/tbd)) is an [OpenStudio Measure](https://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/) that first autodetects _major_ thermal bridges (like balconies, parapets and corners) in an OpenStudio model (.osm), and then _derates_ outside-facing, opaque surface constructions (walls, roofs and exposed floors). It interacts with the [OpenStudio SDK](https://openstudio-sdk-documentation.s3.amazonaws.com/index.html) and relies on _AutomaticMagic_'s [Topolys](https://github.com/automaticmagic/topolys) gem, as well as _rd2_'s [OSut](https://rubygems.org/gems/osut) gem.

This repository houses the numerous automated TBD tests developed over time, in an effort to _lighten_ TBD as a Ruby gem. TBD and its dependencies are pulled-in automatically, before launching both TBD gem and OpenStudio measure RSpec tests.

## New Features  

With each new TBD feature, a decision is made whether to host new RSpec tests here or on TBD's original repository, where - as a general rule - only basic tests are hosted. Bugs or new feature requests for TBD should be submitted [here](https://github.com/rd2/tbd/issues), while those more closely linked to _Topolys_ or _OSut_ should be submitted [here](https://github.com/automaticmagic/topolys/issues) or [here](https://github.com/rd2/osut/issues), respectively.

## Development

The instructions in this section are for those wanting to explore/tweak a cloned/forked version of these tests. We suggest following the same, original OpenStudio installation instructions described [here](https://github.com/rd2/tbd/blob/master/README.md#development).

## Test commands

Run the following (basic) tests in the root repository:
```
bundle update (or 'bundle install')
bundle exec rake
```

For more extensive testing, run the following test suites (also in the root repository):
```
bundle update (or 'bundle install')
bundle exec rake osm_suite:clean
bundle exec rake osm_suite:run
bundle exec rake prototype_suite:clean
bundle exec rake prototype_suite:run
```

Or run all test suites:

```
bundle update (or 'bundle install')
bundle exec rake suites_clean
bundle exec rake suites_run
```

## Run tests using Docker - _optional_

Install [Docker](https://docs.docker.com/desktop/#download-and-install).

Pull the OpenStudio v3.6.1 Docker image:
```
docker pull nrel/openstudio:3.6.1
```

In the root repository:
```
docker run --name test --rm -d -t -v ${PWD}:/work -w /work nrel/openstudio:3.6.1
docker exec -t test bundle update
docker exec -t test bundle exec rake
docker kill test
```
