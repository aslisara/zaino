package com.exploreworld.user;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.OffsetDateTime;

@Entity
@Table(name = "users")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 255)
    private String email;

    @Column(name = "password_hash", nullable = false, length = 100)
    private String passwordHash;

    @Column(name = "display_name", length = 80)
    private String displayName;

    @Column(length = 160)
    private String bio;

    @Column(name = "accent_color", length = 7)
    private String accentColor;

    @Column(name = "created_at", nullable = false, insertable = false, updatable = false)
    private OffsetDateTime createdAt;

    protected User() {
        // JPA için gerekli
    }

    public User(String email, String passwordHash, String displayName) {
        this.email = email;
        this.passwordHash = passwordHash;
        this.displayName = displayName;
    }

    /** Profil alanlarını günceller (e-posta ve şifreye dokunmaz). */
    public void updateProfile(String displayName, String bio, String accentColor) {
        this.displayName = displayName;
        this.bio = bio;
        this.accentColor = accentColor;
    }

    public Long getId() { return id; }
    public String getEmail() { return email; }
    public String getPasswordHash() { return passwordHash; }
    public String getDisplayName() { return displayName; }
    public String getBio() { return bio; }
    public String getAccentColor() { return accentColor; }
    public OffsetDateTime getCreatedAt() { return createdAt; }
}