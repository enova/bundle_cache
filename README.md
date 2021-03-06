# BundleCache

[![Build Status](https://travis-ci.org/enova/bundle_cache.png?branch=master)](https://travis-ci.org/enova/bundle_cache)

Utility for caching bundled gems on S3. Useful for speeding up Travis builds -
it doesn't need to wait for `bundle install` to download/install all gems.

## Installation

Adding this to your Gemfile defeats the purpose. Instead, run

    $ gem install bundle_cache

## Usage

You'll need to set some environment variables to make this work.

```
AWS_ACCESS_KEY_ID=<your aws access key>
AWS_SECRET_ACCESS_KEY=<your aws secret>
AWS_S3_BUCKET=<your bucket name>
BUNDLE_ARCHIVE=<the filename to use for your cache>
```

Optionally, you can set the `AWS_DEFAULT_REGION` variable if you don't use us-east-1.

If you're using [IAM roles](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html) for your S3 credentials you might run into issues like "The AWS Access Key Id you provided does not exist in our records."
In this case you wont need the `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` only the `AWS_SESSION_TOKEN`.

```
AWS_SESSION_TOKEN=<your aws session token>
```

## Travis configuration

Add these to your Travis configuration:
```
bundler_args: --without development --path=~/.bundle
before_install:
- "echo 'gem: --no-ri --no-rdoc' > ~/.gemrc"
- gem install bundler bundle_cache
- bundle_cache_install
after_script:
- bundle_cache
env:
  global:
  - BUNDLE_ARCHIVE="your_project_bundle"
  - AWS_S3_BUCKET="your_bucket"
  - RAILS_ENV=test
```

You'll also want to add your AWS credentials to a secure section in there. Full instructions
are on Matias' site below, but if you've already added the above Travis configuration, this will
add the AWS credentials:

1. Install the travis gem with gem install travis
2. Log into Travis with travis login --auto (from inside your project respository directory)
3. Encrypt your S3 credentials with: travis encrypt AWS_ACCESS_KEY_ID="" AWS_SECRET_ACCESS_KEY="" --add (be sure to add your actual credentials inside the double quotes)

## License

This code was originally written by Matias Korhonen and is available at
http://randomerrata.com/post/45827813818/travis-s3. It is MIT licensed.
