package io.cecg.referenceapplication;

import io.cecg.referenceapplication.api.filters.ConnectionDrainingFilter;
import org.eclipse.jetty.server.handler.EventsHandler;
import org.eclipse.jetty.server.handler.StatisticsHandler;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.web.embedded.jetty.JettyServletWebServerFactory;
import org.springframework.boot.web.server.WebServerFactoryCustomizer;
import org.springframework.stereotype.Component;

@Component
public class GracefulShutdownHandler implements WebServerFactoryCustomizer<JettyServletWebServerFactory> {
    private static final Logger log = LoggerFactory.getLogger(GracefulShutdownHandler.class);

    private final ConnectionDrainingFilter connectionDrainingFilter;

    public GracefulShutdownHandler(ConnectionDrainingFilter connectionDrainingFilter) {
        this.connectionDrainingFilter = connectionDrainingFilter;
    }

    @Override
    public void customize(JettyServletWebServerFactory factory) {
        factory.addServerCustomizers(server -> {
            server.addEventListener(connectionDrainingFilter);

            EventsHandler wrapperStatistics = new StatisticsHandler(); //metrics
            wrapperStatistics.setServer(server);
            wrapperStatistics.setHandler(server.getHandler());

            server.setHandler(wrapperStatistics);
            server.setStopAtShutdown(false);
        });
    }
}