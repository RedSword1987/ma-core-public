/*
    Copyright (C) 2014 Infinite Automation Systems Inc. All rights reserved.
    @author Matthew Lohbihler
 */
package com.serotonin.m2m2.vo.permission;

import java.util.HashSet;
import java.util.Set;

import javax.servlet.http.HttpServletRequest;

import org.apache.commons.lang3.StringUtils;

import com.serotonin.ShouldNeverHappenException;
import com.serotonin.m2m2.Common;
import com.serotonin.m2m2.db.dao.DataPointDao;
import com.serotonin.m2m2.db.dao.DataSourceDao;
import com.serotonin.m2m2.db.dao.SystemSettingsDao;
import com.serotonin.m2m2.rt.event.type.EventType;
import com.serotonin.m2m2.vo.DataPointVO;
import com.serotonin.m2m2.vo.IDataPoint;
import com.serotonin.m2m2.vo.User;
import com.serotonin.m2m2.vo.dataSource.DataSourceVO;
import com.serotonin.m2m2.vo.event.EventTypeVO;

/**
 * @author Matthew Lohbihler
 * 
 */
public class Permissions {
    public interface DataPointAccessTypes {
        int NONE = 0;
        int READ = 1;
        int SET = 2;
        int DATA_SOURCE = 3;
        int ADMIN = 4;
    }

    private Permissions() {
        // no op
    }

    //
    //
    // Valid user
    //
    public static void ensureValidUser() throws PermissionException {
        ensureValidUser(Common.getUser());
    }

    public static void ensureValidUser(HttpServletRequest request) throws PermissionException {
        ensureValidUser(Common.getUser(request));
    }

    public static void ensureValidUser(User user) throws PermissionException {
        if (user == null)
            throw new PermissionException("Not logged in", null);
        if (user.isDisabled())
            throw new PermissionException("User is disabled", user);
    }

    //
    //
    // Administrator
    //
    public static boolean hasAdmin() throws PermissionException {
        return hasAdmin(Common.getUser());
    }

    public static boolean hasAdmin(HttpServletRequest request) throws PermissionException {
        return hasAdmin(Common.getUser(request));
    }

    public static boolean hasAdmin(User user) throws PermissionException {
        ensureValidUser(user);
        return user.isAdmin();
    }

    public static void ensureAdmin() throws PermissionException {
        ensureAdmin(Common.getUser());
    }

    public static void ensureAdmin(HttpServletRequest request) throws PermissionException {
        ensureAdmin(Common.getUser(request));
    }

    public static void ensureAdmin(User user) throws PermissionException {
        if (!hasAdmin(user))
            throw new PermissionException("User is not an administrator", user);
    }

    //
    //
    // Data source admin
    //
    public static void ensureDataSourcePermission(User user, int dsId) throws PermissionException {
        ensureDataSourcePermission(user, new DataSourceDao().get(dsId));
    }

    public static void ensureDataSourcePermission(User user, DataSourceVO<?> ds) throws PermissionException {
        if (!hasDataSourcePermission(user, ds))
            throw new PermissionException("User does not have permission to data source", user);
    }

    public static boolean hasDataSourcePermission(User user, int dsId) throws PermissionException {
        return hasDataSourcePermission(user, new DataSourceDao().get(dsId));
    }

    public static boolean hasDataSourcePermission(User user, DataSourceVO<?> ds) throws PermissionException {
        ensureValidUser(user);
        if (user.isAdmin())
            return true;
        return permissionContains(ds.getEditPermission(), user.getPermissions());
    }

    public static void ensureDataSourcePermission(User user) throws PermissionException {
        if (!hasDataSourcePermission(user))
            throw new PermissionException("User does not have permission to any data sources", user);
    }

    public static boolean hasDataSourcePermission(User user) throws PermissionException {
        ensureValidUser(user);
        String p = SystemSettingsDao.getValue(SystemSettingsDao.PERMISSION_DATASOURCE, "");
        return hasPermission(user, p);
    }

    //
    //
    // Data point access
    //
    public static void ensureDataPointReadPermission(User user, IDataPoint point) throws PermissionException {
        if (!hasDataPointReadPermission(user, point))
            throw new PermissionException("User does not have read permission to point", user);
    }

    public static boolean hasDataPointReadPermission(User user, IDataPoint point) throws PermissionException {
        if (hasPermission(user, point.getReadPermission()))
            return true;
        return hasDataPointSetPermission(user, point);
    }

    public static void ensureDataPointSetPermission(User user, DataPointVO point) throws PermissionException {
        if (!point.getPointLocator().isSettable())
            throw new ShouldNeverHappenException("Point is not settable");
        if (!hasDataPointSetPermission(user, point))
            throw new PermissionException("User does not have set permission to point", user);
    }

    public static boolean hasDataPointSetPermission(User user, IDataPoint point) throws PermissionException {
        if (hasPermission(user, point.getSetPermission()))
            return true;
        String dsPermission = new DataSourceDao().getEditPermission(point.getDataSourceId());
        return hasPermission(user, dsPermission);
    }

    public static int getDataPointAccessType(User user, IDataPoint point) {
        if (user == null || user.isDisabled())
            return DataPointAccessTypes.NONE;
        if (user.isAdmin())
            return DataPointAccessTypes.ADMIN;

        String dsPermission = new DataSourceDao().getEditPermission(point.getDataSourceId());
        if (hasPermission(user, dsPermission))
            return DataPointAccessTypes.DATA_SOURCE;

        if (hasPermission(user, point.getSetPermission()))
            return DataPointAccessTypes.SET;
        if (hasPermission(user, point.getReadPermission()))
            return DataPointAccessTypes.READ;
        return DataPointAccessTypes.NONE;
    }

    //
    //
    // Event access
    //
    public static boolean hasEventTypePermission(User user, EventType eventType) {
        if (hasAdmin(user))
            return true;

        if (eventType.getEventType().equals(EventType.EventTypeNames.DATA_POINT)){
            DataPointVO point = new DataPointDao().get(eventType.getDataPointId());
            return hasDataPointReadPermission(user, point);
        }else if (eventType.getEventType().equals(EventType.EventTypeNames.DATA_SOURCE)){
        	DataSourceVO<?> ds = new DataSourceDao().get(eventType.getDataSourceId());
        	return hasDataSourcePermission(user, ds);
        }

        return false;
    }

    public static void ensureEventTypePermission(User user, EventType eventType) throws PermissionException {
        if (!hasEventTypePermission(user, eventType))
            throw new PermissionException("User does not have permission to the event", user);
    }

    public static void ensureEventTypePermission(User user, EventTypeVO eventType) throws PermissionException {
        ensureEventTypePermission(user, eventType.createEventType());
    }

    //
    // Utility
    //
    public static boolean hasPermission(User user, String query) {
        if (hasAdmin(user))
            return true;
        return permissionContains(query, user.getPermissions());
    }

    /**
     * Checks if the given query matches the given group list. Each is a comma-delimited list of tags, where if any
     * tag in the query string matches any tag in the groups string, true is returned. In other words, if there is
     * any intersection in the tags, permission is granted.
     * 
     * @param query
     *            the granted permission tags
     * @param groups
     *            the owned permission tags
     * @return true if permission is granted, false otherwise.
     */
    public static boolean permissionContains(String query, String groups) {
        if (StringUtils.isEmpty(query) || StringUtils.isEmpty(groups))
            return false;

        String[] queryParts = query.split(",");
        String[] groupParts = groups.split(",");
        for (String queryPart : queryParts) {
            if (StringUtils.isEmpty(queryPart))
                continue;
            for (String groupPart : groupParts) {
                if (StringUtils.equals(queryPart.trim(), groupPart.trim()))
                    return true;
            }
        }

        return false;
    }

    /**
     * Provides detailed information on the permission provided to a user for a given query string.
     */
    public static PermissionDetails getPermissionDetails(String query, User user) {
        PermissionDetails d = new PermissionDetails(user.getUsername());

        d.setAdmin(user.isAdmin());

        if (!StringUtils.isEmpty(user.getPermissions())) {
            for (String s : user.getPermissions().split(",")) {
                if (!StringUtils.isEmpty(s))
                    d.addGroup(s);
            }

            if (!StringUtils.isEmpty(query)) {
                for (String queryPart : query.split(",")) {
                    if (StringUtils.isEmpty(queryPart))
                        continue;

                    for (String groupPart : d.getAllGroups()) {
                        if (StringUtils.equals(queryPart.trim(), groupPart.trim()))
                            d.addMatchingGroup(groupPart);
                    }
                }
            }
        }

        return d;
    }

    public static Set<String> explodePermissionGroups(String groups) {
        Set<String> set = new HashSet<>();

        if (!StringUtils.isEmpty(groups)) {
            for (String s : groups.split(",")) {
                if (!StringUtils.isEmpty(s))
                    set.add(s);
            }
        }

        return set;
    }
}
