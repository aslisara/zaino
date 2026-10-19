package com.exploreworld.user;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
public class AccountRepository {

    private final JdbcTemplate jdbc;

    public AccountRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /** stickers tablosunda users'a yabancı anahtar yok, bu yüzden elle silinir. */
    public int deleteStickers(Long userId) {
        return jdbc.update("DELETE FROM stickers WHERE user_id = ?", userId);
    }

    /** Favoriler, geziler ve AI sayacı ON DELETE CASCADE ile otomatik silinir. */
    public int deleteUser(Long userId) {
        return jdbc.update("DELETE FROM users WHERE id = ?", userId);
    }
}
