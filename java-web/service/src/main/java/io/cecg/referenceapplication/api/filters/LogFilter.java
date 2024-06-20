package io.cecg.referenceapplication.api.filters;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.springframework.stereotype.Component;
import org.springframework.util.StopWatch;
import org.springframework.util.StringUtils;

import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

@Component
public class LogFilter extends GenericFilter {
    private static final Logger log = LoggerFactory.getLogger(LogFilter.class);

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
        StopWatch watch = new StopWatch();
        watch.start();
        String path = null;

        if (request instanceof HttpServletRequest) {
            path = ((HttpServletRequest) request).getRequestURI();
        }
        int status = 0;

        chain.doFilter(request, response);
        watch.stop();
        if (response instanceof HttpServletResponse) {
            status = ((HttpServletResponse) response).getStatus();
        }
        long time = watch.lastTaskInfo().getTimeMillis();

        if (StringUtils.hasLength(path)) {
            log.info("Request for {} took {} ms. Had status {}.", path, time, status);
        }
    }
}