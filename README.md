# Terraform S3 Lab: scan, fix, prove

I wrote a deliberately careless S3 bucket in Terraform, scanned it with Checkov, fixed it, and scanned it again.

Part of my 30-day cloud-security challenge: **Scan it. Detect it. Harden it.** This is the "harden" part.

**Nothing in this repo was ever deployed to AWS.** The first file is intentionally unsafe (it has a public-read ACL). Do not run `terraform apply` on `original/main.tf`.

## Result

| Version | Passed | Failed |
|---------|--------|--------|
| `original/main.tf` (careless) | 6 | 8 |
| `fixed/main.tf` (hardened) | 16 | 4 |

Scanned with Checkov 3.3.29:

```
py -3.13 -m checkov.main -f original/main.tf --compact --quiet
py -3.13 -m checkov.main -f fixed/main.tf --compact --quiet
```

## What I fixed

| Finding | Fix |
|---------|-----|
| `CKV_AWS_20` bucket ACL allows public READ | Removed the public-read ACL |
| `CKV2_AWS_6` no public access block | Added `aws_s3_bucket_public_access_block` with all four settings on |
| `CKV_AWS_21` versioning not enabled | Added `aws_s3_bucket_versioning` set to `Enabled` |
| `CKV_AWS_145` not encrypted with KMS | Added a KMS key (with rotation) and `aws_s3_bucket_server_side_encryption_configuration` |
| `CKV2_AWS_64` KMS key has no policy | Added a key policy. This finding did not exist until my KMS fix created it. |

## What I left, and why

These four still fail, on purpose:

| Finding | Why I left it |
|---------|---------------|
| `CKV_AWS_18` access logging | Needs a second bucket to hold the logs |
| `CKV2_AWS_62` event notifications | Needs something to send the events to |
| `CKV2_AWS_61` lifecycle rule | Depends on how long the data should be kept |
| `CKV_AWS_144` cross-region replication | Needs a second region and a second bucket, which is a design and cost decision |

For a real bucket holding real data I would decide on each of these deliberately. For a demo bucket with no purpose, adding them would just be noise.

## What I learned

- Fixing one problem can create a new finding. Adding the KMS key fixed encryption, but the key itself then failed its own check until I gave it a policy.
- A scan counts rules, not safety. A high pass count does not mean a bucket is secure.
- Check which file you are editing before you paste. I pasted the fix into the original once and the scan numbers did not change, which is how I caught it.
- Check the file size after a change. An unexpectedly small file means something was overwritten.
- I saved scan output to a file and pulled the summary out with `Select-String`, so the before and after numbers are easy to compare.

## Limits

- Checkov reads the code. It cannot see the real state of an AWS account.
- I never ran `terraform validate`, `plan` or `apply`, because Terraform is not installed on this machine. The files are scanned, not tested.
- The bucket name is a placeholder. Real S3 bucket names must be unique worldwide.
- The key policy gives the account root full access to the key, which is the standard starting point. A real setup would add narrower roles.

## Next ideas

- Install Terraform and run `terraform validate` and `terraform plan`.
- Add the access-logging bucket and see how the scan changes.
- Run the same scan in GitHub Actions, like my other labs.
