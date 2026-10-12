package dev.mlkem.transit;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
public class Application {

    public static void main(String[] args) {
        // JSSE lee esta propiedad al crear el SSLContext. Spring Boot no tiene
        // grupos con nombre en SslBundles, así que no vive en application.properties.
        System.setProperty("jdk.tls.namedGroups", "X25519MLKEM768");
        SpringApplication.run(Application.class, args);
    }
}

@RestController
class EchoController {

    @GetMapping("/echo")
    String echo() {
        return "ok\n";
    }
}
