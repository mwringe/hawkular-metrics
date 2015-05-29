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
package org.hawkular.metrics.api.jaxrs.handler;

import static javax.ws.rs.core.MediaType.APPLICATION_JSON;

import com.wordnik.swagger.annotations.ApiOperation;
import javax.servlet.ServletContext;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.Response;
import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlRootElement;

/**
 * @author mwringe
 */
@Path("/")
public class BaseHandler {

    public static final String PATH = "/";

    @GET
    @Produces(APPLICATION_JSON)
    @ApiOperation(value = "Returns some basic information about the Hawkular Metrics service.",
                  response = String.class, responseContainer = "Map")
    public Response baseJSON(@Context ServletContext context) {

        String version = context.getInitParameter("hawkular.metrics.version");
        if (version == null) {
            version = "undefined";
        }

        HawkularMetricsBase hawkularMetrics = new HawkularMetricsBase();
        hawkularMetrics.version = version;

        return Response.ok(hawkularMetrics).build();
    }

    @XmlRootElement(name = "Hawkular-Metrics")
    private class HawkularMetricsBase {

        String name = "Hawkular-Metrics";
        String version;

        @XmlElement(name = "name")
        public String getName() {
            return name;
        }

        public void setVersion(String version) {
            this.version = version;
        }

        @XmlElement(name = "version")
        public String getVersion() {
            return version;

        }
    }
}