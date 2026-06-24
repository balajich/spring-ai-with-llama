package com.techcorp.smarthr.controller;

import com.techcorp.smarthr.model.BookingConfirmation;
import com.techcorp.smarthr.model.BookingRequest;
import com.techcorp.smarthr.model.CalendarSlot;
import com.techcorp.smarthr.service.CalendarService;
import org.springframework.web.bind.annotation.*;

// The pre-existing REST API — used today by the HR team's calendar UI.
// This controller has no knowledge of MCP or LLMs. mcp-server wraps these
// endpoints as MCP tools without modifying this code.
@RestController
@RequestMapping("/api/calendar")
public class CalendarRestController {

    private final CalendarService calendarService;

    public CalendarRestController(CalendarService calendarService) {
        this.calendarService = calendarService;
    }

    @GetMapping("/availability")
    public CalendarSlot checkAvailability(@RequestParam String date, @RequestParam String time) {
        return calendarService.checkAvailability(date, time);
    }

    @PostMapping("/bookings")
    public BookingConfirmation bookInterview(@RequestBody BookingRequest request) {
        return calendarService.bookInterview(request.date(), request.time(), request.candidateInfo());
    }
}
