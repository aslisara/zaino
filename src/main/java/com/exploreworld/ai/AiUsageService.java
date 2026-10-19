package com.exploreworld.ai;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.time.ZoneId;

@Service
public class AiUsageService {

    private static final ZoneId ZONE = ZoneId.of("Europe/Istanbul");

    private final AiUsageRepository repository;
    private final int dailyLimit;

    public AiUsageService(AiUsageRepository repository,
                          @Value("${app.ai.daily-limit:30}") int dailyLimit) {
        this.repository = repository;
        this.dailyLimit = dailyLimit;
    }

    /** Kullanıcının günlük hakkını bir artırır; limit aşılırsa 429 fırlatır. */
    public void consume(Long userId) {
        int used = repository.increment(userId, LocalDate.now(ZONE));
        if (used > dailyLimit) {
            throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS,
                    "Günlük yapay zekâ hakkın doldu");
        }
    }
}
