package io.cecg.referenceapplication.api.filters;

import com.google.common.util.concurrent.Uninterruptibles;
import org.eclipse.jetty.util.component.LifeCycle;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

@Component
public class ConnectionDrainingFilter extends OncePerRequestFilter implements LifeCycle.Listener {
    private static final Logger log = LoggerFactory.getLogger(ConnectionDrainingFilter.class);
    private final AtomicBoolean shuttingDown = new AtomicBoolean(false);
    private final Integer drainingMs;

    public ConnectionDrainingFilter(@Value("${server.drainingMs}") Integer drainingMs) {
        this.drainingMs = drainingMs;
    }

    @Override
    public void lifeCycleStopping(LifeCycle event) {
        log.info("Draining connections");
        shuttingDown.set(true);
        Uninterruptibles.sleepUninterruptibly(drainingMs, TimeUnit.MILLISECONDS);
        log.info("Finished draining connections");

    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain) throws ServletException, IOException {
        if(shuttingDown.get()) {
            response.addHeader("Connection", "close");
        }
        filterChain.doFilter(request, response);
    }
}