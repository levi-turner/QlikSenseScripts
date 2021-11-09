# Contents

| Script | Dependency | Description |
|:------ |:---------- |:----------- |
| `qlik_sense_purge_unused_user_access_passes.ps1` | [Qlik-Cli](https://github.com/ahaydon/Qlik-Cli) | Removes unused user access passes based on an inactivity threshold |
| `qlik_sense_pwd_change.ps1` | [Qlik-Cli](https://github.com/ahaydon/Qlik-Cli) | Changes the Qlik Sense service account password, both on the Windows level and on the monitor_app_* data connections present in Qlik Sense June 2017 onward (as of Qlik Sense April 2018) |
| `qlik_sense_update_max_quota.ps1` | [Qlik-Cli](https://github.com/ahaydon/Qlik-Cli) | Updates the AppQuota value for a Qlik Sense site |
| `qsr_restore.ps1` | None | Functional restoration of a Qlik Sense site from a .TAR backup (supports Qlik Sense June 2017 - September 2018) |
| `qlik_sense_qrs_generic-GET.ps1` | None | Example of how to make a GET RESTful QRS API call without dependencies |
| `qlik_sense_qrs_generic-POST.ps1` | None | Example of how to make a POST RESTful QRS API call without dependencies |
| `qlik_sense-compare_qmc_vs_disk.ps1` | None | Diffs the apps present in the QMC vs. the files on disk |
| `qs-cli-change_app_owner.ps1` | [Qlik-Cli](https://github.com/ahaydon/Qlik-Cli) | Changes app ownership to a new user |
| `qs-cli-delete_old_apps.ps1` | [Qlik-Cli](https://github.com/ahaydon/Qlik-Cli) | Deleting apps created over a date threshold |
| `qs-cli-disable_rule.ps1` | [Qlik-Cli](https://github.com/ahaydon/Qlik-Cli) | Disables an arbitrary security rule |
| `qs-cli-export_custom_rules.ps1` | [Qlik-Cli](https://github.com/ahaydon/Qlik-Cli) | Exports all custom security rules to JSON |
| `qs-cli-export_extension.ps1` | [Qlik-Cli](https://github.com/ahaydon/Qlik-Cli) | Exporting a named extension |
| `qs-cli-export_no_data.ps1` | [Qlik-Cli](https://github.com/ahaydon/Qlik-Cli) | Exporting an app with no data |
| `qs-cli-get_app-publish.ps1` | [Qlik-Cli](https://github.com/ahaydon/Qlik-Cli) | Publish a named app to a named stream |
| `qs-cli-get_with_multiple_filters_and_custom_props.ps1` | [Qlik-Cli](https://github.com/ahaydon/Qlik-Cli) | An example using multiple filters and custom properties with a filter |
| `qs-cli-make_rule_default.ps1` | [Qlik-Cli](https://github.com/ahaydon/Qlik-Cli) | Changes a security rule's type to Default |
| `qs-cli-metadata_fetch.ps1` | [Qlik-Cli](https://github.com/ahaydon/Qlik-Cli) | Using Qlik-CLI to query the app metadata endpoint |
| `qs-cli-New-QlikLicenseRule.ps1` | [Qlik-Cli](https://github.com/ahaydon/Qlik-Cli) | Module to create a new license rule for User Access Passes |
| `qs-cli-node_add.ps1` | [Qlik-Cli](https://github.com/ahaydon/Qlik-Cli) | Adding a RIM node programmatically |
| `qs-cli-publish_and_replace.ps1` | [Qlik-Cli](https://github.com/ahaydon/Qlik-Cli) | Publish and replacing a Qlik app |
| `qs-cli-reactive_users.ps1` | [Qlik-Cli](https://github.com/ahaydon/Qlik-Cli) | Re-activating inactive users |
| `qs-cli-remove_externally_removed.ps1` | [Qlik-Cli](https://github.com/ahaydon/Qlik-Cli) | Deleting users who are removed externally |
| `qs-cli-update_user.ps1` | [Qlik-Cli](https://github.com/ahaydon/Qlik-Cli) | Updating a user's record with a custom property |
| `qs-generic-log_cleanup.ps1` | None | Removes logs over a specified threshold |
| `qs-generic-postgresql_query_generator_stub.ps1` | None | Stub for generating arbitrary PostgreSQL SQL commands to a file for further use |
| `qs-qps-session_scrape.ps1` | None | Raw PowerShell to retrieve QPS sessions (useful for determining whether users are using Qlik Sense Enterprise on Windows) |
| `qs-qps-ticket_request-auto.ps1` | None | Generate a QPS ticket on a ticket enabled virtual proxy and launch an incognito Chrome process with that ticket |
| `qs-qrs-app_object_timing.ps1` | None | Raw PowerShell QRS API call timed |
| `qs-qrs-elevate_user_rootadmin.ps1` | None | Raw PowerShell QRS API call to elevate an arbitrary user to being a RootAmin |
| `qs-qrs-export_no_data.ps1` | None | Raw PowerShell QRS API call to export an app with no data |
| `qs-qrs-migrate_all_apps.ps1` | None | Raw PowerShell QRS API call to migrate all unmigrated apps |
| `qs-qrs-odag_delete.ps1` | None | Raw PowerShell QRS API call to delete a named ODAG link |
| `qs-qrs-xlsb_whitelisting.ps1` | None | Raw PowerShell QRS API call to add the XLXB filetype QRS's whitelist |
