package com.techcorp.smarthr.service;

import com.techcorp.smarthr.model.BookingConfirmation;
import com.techcorp.smarthr.model.CalendarSlot;
import org.springframework.ai.tool.annotation.Tool;
import org.springframework.ai.tool.annotation.ToolParam;
import org.springframework.stereotype.Service;

import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

// Methods annotated with @Tool are exposed to the LLM via ChatClient.defaultTools().
// The LLM reads the descriptions to decide when and how to call them.
@Service
public class CalendarService {

    private final Set<String> bookedSlots = new HashSet<>();

    @Tool(description = "Check if a specific date and time slot is available for scheduling an interview")
    public CalendarSlot checkAvailability(
            @ToolParam(description = "Date in yyyy-MM-dd format") String date,
            @ToolParam(description = "Time in HH:mm 24-hour format") String time) {
        boolean available = !bookedSlots.contains(slot(date, time));
        return new CalendarSlot(date, time, available);
    }

    @Tool(description = "Book an interview slot in the calendar for a candidate. Only call this after confirming the slot is available.")
    public BookingConfirmation bookInterview(
            @ToolParam(description = "Date in yyyy-MM-dd format") String date,
            @ToolParam(description = "Time in HH:mm 24-hour format") String time,
            @ToolParam(description = "Candidate name and role being interviewed for") String candidateInfo) {
        String slotKey = slot(date, time);
        if (!bookedSlots.add(slotKey)) {
            return new BookingConfirmation(null, date, time, false);
        }
        String meetingId = "MTG-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        return new BookingConfirmation(meetingId, date, time, true);
    }

    private String slot(String date, String time) {
        return date + "T" + time;
    }
}
