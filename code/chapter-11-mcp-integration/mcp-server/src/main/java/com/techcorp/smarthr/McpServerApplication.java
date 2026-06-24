package com.techcorp.smarthr;

import com.techcorp.smarthr.tool.CalendarMcpTools;
import org.springframework.ai.tool.ToolCallbackProvider;
import org.springframework.ai.tool.method.MethodToolCallbackProvider;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class McpServerApplication {

    public static void main(String[] args) {
        SpringApplication.run(McpServerApplication.class, args);
    }

    // Registers CalendarMcpTools' @Tool methods with the MCP server auto-configuration.
    // Any MCP client that connects to this server will see checkAvailability and
    // bookInterview in its tool list.
    @Bean
    public ToolCallbackProvider calendarToolCallbackProvider(CalendarMcpTools calendarMcpTools) {
        return MethodToolCallbackProvider.builder()
                .toolObjects(calendarMcpTools)
                .build();
    }
}
