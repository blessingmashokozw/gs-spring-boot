package com.example.springboot;

import org.junit.jupiter.api.Test;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.resttestclient.autoconfigure.AutoConfigureRestTestClient;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.client.RestTestClient;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureRestTestClient
class HelloControllerIntegrationTest {

  @Autowired
  private RestTestClient client;

  @Test
  void helloEndpointReturnsCorrectResponse() {
    client.get().uri("/").exchangeSuccessfully()
        .expectBody(String.class)
        .isEqualTo("Greetings from Spring Boot with docker!");
  }
}
