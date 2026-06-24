package com.techcorp.smarthr.service;

import com.techcorp.smarthr.model.BookingConfirmation;
import com.techcorp.smarthr.model.CalendarSlot;
import org.springframework.stereotype.Service;

import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

// The pre-existing business logic — imagine it already shipped as a REST API
// for the HR team's internal tools, long before MCP existed. Nothing here is
// aware of LLMs, tools, or MCP.
@Service
public class CalendarService {

    private final Set<String> bookedSlots = ConcurrentHashMap.newKeySet();

    public CalendarSlot checkAvailability(String date, String time) {
        boolean available = !bookedSlots.contains(key(date, time));
        return new CalendarSlot(date, time, available);
    }

    public BookingConfirmation bookInterview(String date, String time, String candidateInfo) {
        String slotKey = key(date, time);
        if (!bookedSlots.add(slotKey)) {
            return new BookingConfirmation(null, date, time, false);
        }
        String meetingId = "MTG-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        return new BookingConfirmation(meetingId, date, time, true);
    }

    private String key(String date, String time) {
        return date + "T" + time;
    }
}
