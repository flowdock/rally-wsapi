# rally-wsapi

Rally WSAPI client written in Ruby.

## Usage

In order to authenticate to WSAPI, you will need to obtain an API key for the Rally account. This can be done via [Rally OAuth](https://github.com/RallySoftware/rally-oauth-examples), for example.

Once you have the API key, you can initialize the session object with the key:
```
s = Wsapi::Session.new("deadbeefdeadbeef")
```

The constructor also accepts the following options:
  * `:workspace_id`, if not given, user's default workspace is used for queries
  * `:version`, WSAPI version, default is `3.0`
  * `:timeout`, request time out in seconds
  * `oauth2`, see: (using WSAPI with OAuth2)[https://github.com/flowdock/rally-wsapi#using-wsapi-with-oauth2]

### Using WSAPI with OAuth2

Authenticating to WSAPI is also possible with OAuth2. Access token used in
requests is given in place of the API token. Refresh token can be supplied with
`Wsapi::Session#.setup_refresh_token(client_id, client_secret, refresh_token)`
method. It takes optional block parameter, which is called every time the
access token is refreshed.

## Method reference for Session

Some methods accept an optional hash that can have the following options:
 * `:query`, add conditions for fetching objects. E.g. `(UserName = "John")`, see WSAPI documentation for details about the syntax
 * `:start`, default: `1`, fetch results starting from given number
 * `:workspace`, override workspace setting of the session
 * `:pagesize`, default: `200`, page size for results
 * `:fetch`, default: `true`, fetch full objects

#### Get the authenticated user
```
get_current_user
```

#### Get a user
```
get_user(user_id)
```

#### Get a user by username
```
get_user_by_username(username)
```

#### Get users by query
```
get_users(query_string = nil)
```
If the query_string is present, applies it to the request. Otherwise returns all users. See WSAPI documentation for details about query_string syntax.

#### Get the subscription of the authenticated user
```
get_user_subscription
```

#### Get a subscription
```
get_project(subscription_id)
```

#### Get a project
```
get_project(project_id)
```

#### Get projects of the authenticated user
```
get_projects(opts = {})
```

#### Get team members in a project
```
get_team_members(project_id, opts = {})
```

#### Get editors in a project
```
get_editors(project_id, opts = {})
```

### Update any artifact with parameters hash
```
update_artifact(artifact_type, artifact_id, parameters)
```

### Setup refresh token to be used with OAuth2
```
setup_refresh_token(client_id, client_secret, refresh_token, &block)
```

See (Using WSAPI with OAuth2)[https://github.com/flowdock/rally-wsapi#using-wsapi-with-oauth2] for more info.

## Result objects

There's a couple of convenience classes for the following object types:

 * `User`
 * `Subscription`
 * `Project`

 Other object types are represented by the generic `Object` class which the specific types above extend.

#### Object

Methods:
  * `id`, identifier of the object
  * `name`, name of the object
  * `url`, URL of the object
  * `workspace`, name of the object's workspace


#### User

Methods:
  * `username`, username
  * `first_name`, first name
  * `last_name`, last name
  * `name`, full name
  * `email`, email address
  * `admin?`, is the user admin in the subscription?

#### Subscription

Methods:
  * `subscription_id`, subcription identifier

#### Project

Methods:
  * `subscription`, `Subscription` of the project

