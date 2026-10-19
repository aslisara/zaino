package com.exploreworld.sticker;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import org.hibernate.annotations.Generated;
import org.hibernate.generator.EventType;

import java.time.LocalDate;
import java.time.OffsetDateTime;

/** Kullanıcının gittiği bir ülke (isteğe bağlı şehir) için topladığı sticker. */
@Entity
@Table(name = "stickers")
public class Sticker {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(nullable = false, length = 100)
    private String country;

    @Column(length = 100)
    private String city;

    @Column(name = "visited_on")
    private LocalDate visitedOn;

    @Column(length = 500)
    private String note;

    @Generated(event = EventType.INSERT)
    @Column(name = "created_at", nullable = false, insertable = false, updatable = false)
    private OffsetDateTime createdAt;

    protected Sticker() {
        // JPA için gerekli
    }

    public Sticker(Long userId, String country, String city, LocalDate visitedOn, String note) {
        this.userId = userId;
        this.country = country;
        this.city = city;
        this.visitedOn = visitedOn;
        this.note = note;
    }

    public Long getId() { return id; }
    public Long getUserId() { return userId; }
    public String getCountry() { return country; }
    public String getCity() { return city; }
    public LocalDate getVisitedOn() { return visitedOn; }
    public String getNote() { return note; }
    public OffsetDateTime getCreatedAt() { return createdAt; }
}