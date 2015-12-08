/*
 * Copyright 2014-2015 Red Hat, Inc. and/or its affiliates
 * and other contributors as indicated by the @author tags.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.hawkular.metrics.api.jaxrs.filter;

import static javax.ws.rs.core.MediaType.APPLICATION_JSON_TYPE;

import javax.inject.Inject;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.Status;
import javax.ws.rs.ext.Provider;

import org.hawkular.metrics.api.jaxrs.MetricsServiceLifecycle;
import org.hawkular.metrics.api.jaxrs.MetricsServiceLifecycle.State;
import org.hawkular.metrics.api.jaxrs.handler.StatusHandler;
import org.hawkular.metrics.core.api.ApiError;
import org.jboss.resteasy.annotations.interception.ServerInterceptor;
import org.jboss.resteasy.core.ResourceMethod;
import org.jboss.resteasy.core.ServerResponse;
import org.jboss.resteasy.spi.Failure;
import org.jboss.resteasy.spi.HttpRequest;
import org.jboss.resteasy.spi.interception.PreProcessInterceptor;

/**
 * @author Matt Wringe
 */
@Provider
@ServerInterceptor
public class MetricsServiceStateFilter implements PreProcessInterceptor {

    private static final String STARTING = "Service unavailable while initializing.";
    private static final String FAILED = "Internal server error.";
    private static final String STOPPED = "The service is no longer running.";

    @Inject
    private MetricsServiceLifecycle metricsServiceLifecycle;

    @Override
    public ServerResponse preProcess(HttpRequest request, ResourceMethod method) throws Failure,
            WebApplicationException {
        String path = request.getUri().getPath();

        if (path.startsWith(StatusHandler.PATH)) {
            // The status page does not require the MetricsService to be up and running.
            return null;
        }

        if (metricsServiceLifecycle.getState() == State.STARTING) {
            // Fail since the Cassandra cluster is not yet up yet.
            Response response = Response.status(Status.SERVICE_UNAVAILABLE)
                    .type(APPLICATION_JSON_TYPE)
                    .entity(new ApiError(STARTING))
                    .build();
            return ServerResponse.copyIfNotServerResponse(response);
        } else if (metricsServiceLifecycle.getState() == State.FAILED) {
            // Fail since an error has occured trying to start the Metrics service
            Response response = Response.status(Status.INTERNAL_SERVER_ERROR)
                    .type(APPLICATION_JSON_TYPE)
                    .entity(new ApiError(FAILED))
                    .build();
            return ServerResponse.copyIfNotServerResponse(response);
        } else if (metricsServiceLifecycle.getState() == State.STOPPED ||
                metricsServiceLifecycle.getState() == State.STOPPING) {
            Response response = Response.status(Status.SERVICE_UNAVAILABLE)
                    .type(APPLICATION_JSON_TYPE)
                    .entity(new ApiError(STOPPED))
                    .build();
            return ServerResponse.copyIfNotServerResponse(response);
        }

        return null;
    }
}
