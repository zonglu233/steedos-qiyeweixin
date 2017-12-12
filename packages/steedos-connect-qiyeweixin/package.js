Package.describe({
  summary: "connect steedos accounts with dingtalk",
  "version": "0.0.1",
  "name": "steedos:connect-qiyeweixin"
});

Npm.depends({
  "wechat-crypto": "0.0.2",
  'wxbizmsgcrypt':'1.0.6',
  'request': '2.65.0',
  'node-schedule': '1.1.1',
  'http':'0.0.0',
  'redis':'2.8.0',
  'url':'0.11.0',
  'querystring':'0.2.0',
  'xml2json':'0.11.0'
});

Package.onUse(function(api) {
  api.versionsFrom("METEOR@1.0.3");
  api.use('steedos:base');
    api.use('steedos:accounts');
    api.use('steedos:theme');
  api.use('accounts-base', ['client', 'server']);
  api.imply('accounts-base', ['client', 'server']);
  api.use('accounts-oauth', ['client', 'server']);
  api.use('simple:json-routes@2.1.0');
  api.use('coffeescript');
  api.use('mongo@1.1.12');

  api.use('oauth', ['client', 'server']);
  api.use('oauth2', ['client', 'server']);
  api.use('http', ['server']);
  api.use('templating', 'client');
  api.use('random', 'client');
  api.use('underscore', 'server');
  api.use('service-configuration',['client','server']);

  api.addFiles('server_callback.coffee', 'server');
  api.addFiles('qywx.coffee', 'server');
  api.addFiles('qywx_api.coffee', 'server');


  api.export('Qiyeweixin');
});