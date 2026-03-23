package com.example.springboot;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

  @GetMapping("/")
  public String index() {
    return "Greetings from Spring Boot!";
  }

  @GetMapping("/status")
  public String status() {
    return "Application is running v1!";
  }

   @GetMapping("/version")
  public String version() {
    return "Application is running v1!";
  }


  @GetMapping("/users")
  public String version() {
    return "You will get a list of users here!";
  }
}
