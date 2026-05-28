function fn() {
    // Override base.url from the command line:
    //   mvn test -Dtest=Chapter01Test -Dbase.url=http://localhost:9090
    var baseUrl = karate.properties['base.url'] || 'http://localhost:8080';

    var config = {
        baseUrl: baseUrl
    };

    karate.log('=== Karate Config ===');
    karate.log('Base URL :', baseUrl);
    karate.log('Environment:', karate.env || 'default');
    karate.log('====================');

    // Give every request a generous timeout — LLM calls can be slow
    karate.configure('connectTimeout', 10000);
    karate.configure('readTimeout', 120000);

    return config;
}
