# JEBot

JEBot is a Discord Bot written by John Bradley for personal use. It is released here on GitHub simply for the benefit of anyone else who wishes to write a Discord Bot similar to this one, either as an example or as a jumping-off point. This isn't really a feature complete bot and things can drastically change, and this readme isn't a guide on how to create and add a bot to your server.

# Requirements
- Perl 5 (Test 5.32.1)

# Dependencies

- JSON
- Switch
- File::Random
- File::Slurp
- Text::Padding
- List::Util
- AnyEvent::WebSocket::Client;
- AnyEvent::HTTP
- LWP::UserAgent
- URI
- HTTP::Request
- HTTP::Headers

# Setting up JEBot

- Create a bot and get a [token from Discord](https://discordapp.com/developers/applications/).
- Clone this repository somewhere.
- Install Perl 5 and dependencies.
- Remove .pub from all files pulled from the repository: `jebot.pub`, `auth_users.pub`.
- Add your [userid](https://support.discord.com/hc/en-us/articles/206346498) to `auth_users`.
```
   1234567890985432
```
- On line 44, add your token from discord:
```
   my $token = ' . . . ';
```
- Run `jebot` without any CLI arguments.
- Invite your bot to your server, set permissions, and call it a day.

# Configuration Options

- Line 44: bot token
- Line 64: bot status on login

# Latest Changes

## 0-α1
- Created the project in Github
- Updated all code to contain copyright and licensing
- Added documentation

# Tested System Configurations

| OS        | Perl   |
| --------- | ------ |
| Debian 11 | 5.32.1 |

If you have a system configuration not listed, and would like to contribue this data, please [provide feedback](https://github.com/userjack6880/jebot/issues).

# Release Cycle and Versioning

There will be no release cycle. It'll be whenever there's a new version. Versioning is under the Anomaly Versioning Scheme (2022), as outlined in `VERSIONING` under `docs`.

# Support

Support will be provided as outlined in the following schedule. For more details, see `SUPPORT`.

| Version                       | Support Level    | Released       | End of Support | End of Life   |
| ----------------------------- | ---------------- | -------------- | -------------- | ------------- |
| 0-α1                          | Full Support     | 26 July 2022   | TBD            | TBD           |

# Contributing

Public contributions are encouraged. Please review `CONTRIBUTING` under `docs` for contributing procedures. Additionally, please take a look at our `CODE_OF_CONDUCT`. By participating in this project you agree to abide by the Code of Conduct.

# Contributors

Primary Contributors
- John Bradley - Initial Work

Thanks to [all who contributed](https://github.com/userjack6880/jebot/graphs/contributors) and [have given feedback](https://github.com/userjack6880/jebot/issues?q=is%3Aissue).

# Licenses, Copyrights, and Attributions

Copyright (C) 2022 John Bradley (userjack6880). JEBot is released under GNU GPLv3. See `LICENSE`.

The `dclient.pm` module is released under the same license as the main project as a relicense from the original. This is allowed as it is considered a "Modified Version" of the Original "Standard Version" of [AnyEvent::Discord::Client](https://github.com/topaz/perl-AnyEvent-Discord-Client), a Discord client library for the AnyEvent framework.

The Standard Version of AnyEvent::Discord::Client is Copyright (C) 2019 Eric Wastl, licensed under the Artistic License 2.0. A full copy of this license is available [here](http://www.perlfoundation.org/artistic_license_2_0).

The Modified Version differs from the Standard Version in that it is now possible to set a status automatically when JEBot is started. Future plans are to further integrate `dclient.pm` into JEBot with extended features as needed. `dclient.pm` is not intended to be distributed separate of JEBot, and thus should not conflict with a user's installation of AnyEvent::Discord::Client.