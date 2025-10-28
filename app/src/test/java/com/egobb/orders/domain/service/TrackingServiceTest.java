package com.egobb.orders.domain.service;

import static org.mockito.Mockito.*;

import com.egobb.orders.domain.model.OrderTimeline;
import com.egobb.orders.domain.model.Status;
import com.egobb.orders.domain.ports.EventAppender;
import com.egobb.orders.domain.ports.OrderTimelineRepository;
import com.egobb.orders.domain.vo.TrackingEventVo;
import java.time.Instant;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class TrackingServiceTest {

  @Mock OrderTimelineRepository repo;
  @Mock EventAppender appender;

  @InjectMocks TrackingService service;

  @Test
  void process_validEvent_savesAggregate_and_appendsHistory() {
    final var tl = spy(new OrderTimeline("o1", Status.PICKED_UP_AT_WAREHOUSE, null));
    when(this.repo.findById("o1")).thenReturn(Optional.of(tl));

    final var vo = new TrackingEventVo("o1", Status.OUT_FOR_DELIVERY, Instant.now());

    this.service.process(vo);

    verify(tl).register(vo);
    verify(this.repo).save(tl);
    verify(this.appender, times(1)).append(anyList());
  }

  @Test
  void process_invalidEvent_doesNotSave_norAppend() {
    final var tl = spy(new OrderTimeline("o1", Status.DELIVERED, Instant.now()));
    when(this.repo.findById("o1")).thenReturn(Optional.of(tl));
    doReturn(false).when(tl).register(any());

    this.service.process(new TrackingEventVo("o1", Status.OUT_FOR_DELIVERY, Instant.now()));

    verify(this.repo, never()).save(any());
    verify(this.appender, never()).append(anyList());
  }
}
