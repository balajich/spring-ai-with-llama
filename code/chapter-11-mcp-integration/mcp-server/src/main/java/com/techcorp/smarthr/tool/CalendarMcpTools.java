package com.techcorp.smarthr.tool;

import com.techcorp.smarthr.model.BookingConfirmation;
import com.techcorp.smarthr.model.BookingRequest;
import com.techcorp.smarthr.model.CalendarSlot;
import org.springframework.ai.tool.annotation.Tool;
import org.springframework.ai.tool.annotation.ToolParam;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

// This is the adapter layer: it does not contain any scheduling logic itself.
// Every method calls the pre-existing calendar-service REST API over HTTP —
// exactly what a hiring manager's calendar UI does today. MCP just gives an
// LLM the same access, through the same API, via a documented tool schema
// instead of a UI.
@Component
public class CalendarMcpTools {

    private final RestClient restClient;

    public CalendarMcpTools(@Value("${calendar-service.base-url}") String calendarServiceBaseUrl) {
        this.restClient = RestClient.builder().baseUrl(calendarServiceBaseUrl + "/api/calendar").build();
    }

    @Tool(description = "Check if a specific date and time slot is available for scheduling an interview")
    public CalendarSlot checkAvailability(
            @ToolParam(description = "Date in yyyy-MM-dd format") String date,
            @ToolParam(description = "Time in HH:mm 24-hour format") String time) {
        return restClient.get()
                .uri(uriBuilder -> uriBuilder.path("/availability")
                        .queryParam("date", date)
                        .queryParam("time", time)
                        .build())
                .retrieve()
                .body(CalendarSlot.class);
    }

    @Tool(description = "Book an interview slot in the calendar for a candidate. Only call this after confirming the slot is available.")
    public BookingConfirmation bookInterview(
            @ToolParam(description = "Date in yyyy-MM-dd format") String date,
            @ToolParam(description = "Time in HH:mm 24-hour format") String time,
            @ToolParam(description = "Candidate name and role being interviewed for") String candidateInfo) {
        return restClient.post()
                .uri("/bookings")
                .body(new BookingRequest(date, time, candidateInfo))
                .retrieve()
                .body(BookingConfirmation.class);
    }
}
