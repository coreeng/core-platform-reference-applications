package io.cecg.referenceapplication.api.controllers;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class GreetingControllerTest {
    private final GreetingController controller = new GreetingController();

    @Test
    void escapesNameParameter() {
        assertEquals(
                "Hello &lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;!",
                controller.hello("<script>alert(\"xss\")</script>")
        );
    }
}
