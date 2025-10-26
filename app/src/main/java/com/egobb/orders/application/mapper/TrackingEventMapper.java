package com.egobb.orders.application.mapper;

import com.egobb.orders.application.command.EnqueueTrackingEventCmd;
import com.egobb.orders.application.command.ProcessTrackingEventCmd;
import com.egobb.orders.domain.event.TrackingEventReceived;
import com.egobb.orders.domain.vo.TrackingEventVo;
import org.mapstruct.Mapper;

@Mapper
public interface TrackingEventMapper {

	TrackingEventReceived toDomain(final EnqueueTrackingEventCmd enqueueTrackingEventCmd);

	TrackingEventVo toDomain(final ProcessTrackingEventCmd processTrackingEventCmd);

}
