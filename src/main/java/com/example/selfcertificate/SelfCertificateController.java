package com.example.selfcertificate;


import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class SelfCertificateController {

    @RequestMapping("/hello")
    public String test() {
        return "Welcome ICS M&M Team";
    }
}