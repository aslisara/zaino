package com.exploreworld.ai;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;

@Repository
public class AiUsageRepository {

    private final JdbcTemplate jdbc;

    public AiUsageRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /** Kullanıcının o günkü sayacını 1 artırır ve yeni değeri döndürür (tek atomik sorgu). */
    public int increment(Long userId, LocalDate day) {
        Integer count = jdbc.queryForObject(
                "INSERT INTO ai_usage (user_id, usage_date, call_count) VALUES (?, ?, 1) "
                        + "ON CONFLICT (user_id, usage_date) "
                        + "DO UPDATE SET call_count = ai_usage.call_count + 1 "
                        + "RETURNING call_count",
                Integer.class, userId, day);
        return count == null ? 1 : count;
    }
}
