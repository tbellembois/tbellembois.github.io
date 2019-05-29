# Rocket.Chat Shibboleth authentication

[Rocket.Chat](authproxy.dsi.uca.fr) provides SAML2 authentication but does not support (yet) IDP discovery. Shibboleth authentication is not yet possible without a proxy.

# Satosa

[Satosa](https://github.com/IdentityPython/SATOSA) is (from Satosa site):

	"a configurable proxy for translating between different authentication protocols such as SAML2, OpenID Connect and OAuth2."
	
This documentation provides the steps to configure both Rocket.Chat and Satosa to perform Shibboleth authentication in the Renater federation.

## How does it work ?

Satosa provides an SP (called **backend**) an an IDP (called **frontend**) to create a proxy beetween Rocket.Chat and the Renater SAML2 authentication mechanism.

From Satosa site:

	SP -> SAMLFrontend -> SAMLBackend -> discovery to select target IdP -> target IdP
	
# Naming conventions and technical details

- the Rocket.Chat service is called `rocket.dsi.uca.fr`
- the Satosa service is called `authproxy.dsi.uca.fr`
- the SAML2 federation is [Renater](https://www.renater.fr/) with its [published](https://services.renater.fr/federation/technique/metadata) published metadata 

Both Rocket.Chat and Satosa run on Debian 9 on two separated VMWare VMs.

# step 1 Rocket.Chat SAML configuration

The following picture shows the most relevant parts of the configuration.

![ ](/home/thbellem/workspace/workspace_siteperso/tbellembois.github.io/media/satosa/rocket_saml.png  "Rocket.Chat SAML configuration")

The `custom provider` field is a free field. Is is used by Rocket.Chat to build the `custom issuer` endpoint.
Look at the [documentation](https://rocket.chat/docs/administrator-guides/authentication/saml/) documentation for details.

# step 2 Satosa configuration

Create a directory to store Satosa configuration files (`/home/satosa` for me) and retrieve the example files from [github](https://github.com/IdentityPython/SATOSA/tree/master/example) github.

Rename the `.example` files.
Remove the unused files. We will use only the SAML2 backend and frontend plugins.

You should then have the following structure:
```bash
	├── plugins
	│   ├── backends
	│   │   └── saml2_backend.yaml
	│   ├── frontends
	│   │   └── saml2_frontend.yaml
	│   └── microservices
	│       └── static_attributes.yaml
	├── proxy_conf.yaml
	├── internal_attributes.yaml
```

Note that there is a [reported issue](https://github.com/IdentityPython/SATOSA/issues/184) in Satosa that prevents the proxy to start if no microservice is configured. I have kept the `static_attributes` microservice with its default configuration as a workaround.

## proxy.conf

Here is the beginning of the file to be configured. 

- `STATE_ENCRYPTION_KEY` is a free string
- `BASE` is the Satosa proxy URL.
- `COOKIE_STATE_NAME` is a free string

```
BASE: https://authproxy.dsi.uca.fr
INTERNAL_ATTRIBUTES: "internal_attributes.yaml"
COOKIE_STATE_NAME: "SATOSA_PROXY"
STATE_ENCRYPTION_KEY: "mysuperencryptionkey"
CUSTOM_PLUGIN_MODULE_PATHS:
  - "plugins/backends"
  - "plugins/frontends"
  - "plugins/micro_services"
BACKEND_MODULES:
  - "plugins/backends/saml2_backend.yaml"
FRONTEND_MODULES:
  - "plugins/frontends/saml2_frontend.yaml"
MICRO_SERVICES:
  - "plugins/microservices/static_attributes.yaml"
...
```

## internal_attributes.yaml

Fill in carefully this file with the following parameters:

```
attributes:
  address:
    openid: [address.street_address]
    orcid: [addresses.str]
    saml: [postaladdress]
  displayname:
    openid: [nickname]
    orcid: [name.credit-name]
    github: [login]
    saml: [displayName]
  edupersontargetedid:
    facebook: [id]
    linkedin: [id]
    orcid: [orcid]
    github: [id]
    openid: [sub]
    saml: [eduPersonTargetedID]
  givenname:
    facebook: [first_name]
    linkedin: [email-address]
    orcid: [name.given-names.value]
    openid: [given_name]
    saml: [givenName]
  mail:
    facebook: [email]
    linkedin: [email-address]
    orcid: [emails.str]
    github: [email]
    openid: [email]
    saml: [mail]
  name:
    facebook: [name]
    orcid: [name.credit-name]
    github: [name]
    openid: [name]
    saml: [cn]
  surname:
    facebook: [last_name]
    linkedin: [lastName]
    orcid: [name.family-name.value]
    openid: [family_name]
    saml: [sn, surname]
user_id_from_attrs: [mail]
user_id_to_attr: mail
```

This configuration file makes Satosa send the needed SAML2 attributes to Rocket.
Look at [here](https://github.com/IdentityPython/SATOSA/issues/209) here for details.

## plugins/frontends/saml2_frontend.yaml

I have customized only the `config > idp_config > organization` field and removed the `common domain cookie` section.
Look at [here](https://github.com/IdentityPython/SATOSA/issues/205) here for details.

## plugins/backends/saml2_backend.yaml

Fill in carefully this file with the following parameters:

```
module: satosa.backends.saml2.SAMLBackend
name: Saml2
config:
  idp_blacklist_file: 
  sp_config:
    key_file: backend.key
    cert_file: backend.crt
    organization: {display_name: UCA, name: Université Clermont Auvergne, url: 'https://www.uca.fr/'}
    contact_person:
    - {contact_type: technical, email_address: thomas.bellembois@uca.fr, given_name: Technical}
    - {contact_type: support, email_address: thomas.bellembois@uca.fr, given_name: Support}

    metadata:
      local: [idp.xml]

    entityid: <base_url>/<name>/proxy_saml2_backend.xml
    accepted_time_diff: 60
    service:
      sp:
        ui_info:
          display_name:
            - lang: en
              text: "Rocket Chat"
          description:
            - lang: en
              text: "Rocket Chat"
          information_url:
            - lang: en
              text: "https://rocket.dsi.uca.fr/"
          privacy_statement_url:
            - lang: en
              text: "https://rocket.dsi.uca.fr/"
          keywords:
            - lang: se
              text: ["RocketChat", "SP-SE"]
            - lang: en
              text: ["RocketChat", "SP-EN"]
          logo:
            text: "http://sp.logo.url/"
            width: "100"
            height: "100"
        authn_requests_signed: true
        want_response_signed: true
        allow_unsolicited: true
        endpoints:
          assertion_consumer_service:
          - [<base_url>/<name>/acs/post, 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST']
          - [<base_url>/<name>/acs/redirect, 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect']
          discovery_response:
          - [<base_url>/<name>/disco, 'urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol']
        name_id_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient'
        name_id_format_allow_create: true
  # disco_srv must be defined if there is more than one IdP in the metadata specified above
  disco_srv: https://discovery.renater.fr/renater
```

# step 3 certificates generation and SAML metadata retrieval

- Generate backend and frontend certificates:

```bash
for i in frontend backend; do   openssl req -batch -x509 -nodes -days 3650 -newkey rsa:2048      -keyout ./$i.key -out ./$i.crt      -subj /CN=authproxy.dsi.uca.fr; done;
```

You will also need an https certificate. We use a TERENA certificate for this.

- Retrieve `sp.xml`

`sp.xml` can be retrieve from the `custom issuer` endpoint of you Rocket.Chat SAML2 configuration.

```bash
	wget https://rocket.dsi.uca.fr/_saml/metadata/uca -O sp.xml
```

- Retrieve `idp.xml`

`idp.xml` is provided and updated by Renater

```bash
	wget https://metadata.federation.renater.fr/renater/main/main-idps-renater-metadata.xml -O idp.xml
```

	This command must be put in a cron job to update the local metadata from Renater.

# step 4 renater SP registration

You then need to register your backend `https://authproxy.dsi.uca.fr/Saml2/proxy_saml2_backend.xml` as an SP in Renater.