<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns="http://hl7.org/fhir"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:cda="urn:hl7-org:v3" 
    xmlns:fhir="http://hl7.org/fhir"
    xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml"
    version="2.0">
    
        
    <xsl:template match="cda:substanceAdministration[cda:templateId/@root='2.16.840.1.113883.10.20.22.4.52'][@moodCode='EVN']" mode="bundle-entry">
       <xsl:call-template name="create-bundle-entry"/>
   </xsl:template>
    
    <!--  
    <xsl:template
        match="cda:substanceAdministration[cda:templateId/@root='2.16.840.1.113883.10.20.22.4.16'][@moodCode='EVN']"
        mode="reference">
        <xsl:param name="sectionEntry">false</xsl:param>
        <xsl:param name="listEntry">false</xsl:param>
        <xsl:choose>
            <xsl:when test="$sectionEntry='true'">
                <entry>
                    <reference value="urn:uuid:{@lcg:uuid}"/>
                </entry></xsl:when>
            <xsl:when test="$listEntry='true'">
                <entry><item>
                    <reference value="urn:uuid:{@lcg:uuid}"/></item>
                </entry></xsl:when>
            <xsl:otherwise>
                <reference value="urn:uuid:{@lcg:uuid}"/>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>
    -->
      
    <xsl:template match="cda:substanceAdministration[cda:templateId/@root='2.16.840.1.113883.10.20.22.4.52'][@moodCode='EVN']">
        <Immunization>
            <xsl:call-template name="add-meta"/>
            <xsl:apply-templates select="cda:id"/>
            <xsl:apply-templates select="cda:statusCode"/>
            <xsl:choose>
                <!-- TODO: For FHIR R4, notGiven will become a status code of not-done and notGiven goes away -->
                <xsl:when test="@negationInd='true'">
                    <notGiven value="true"/>
                </xsl:when>
                <xsl:otherwise>
                    <notGiven value="false"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="cda:consumable" mode="immunization"/>
            
            <xsl:call-template name="subject-reference">
                <xsl:with-param name="element-name">patient</xsl:with-param>
            </xsl:call-template>
            <xsl:apply-templates select="cda:effectiveTime" mode="instant">
                <xsl:with-param name="element-name">date</xsl:with-param>
            </xsl:apply-templates>
            
            <xsl:comment>Defaulting primarySource to false since this info is not in the C-CDA Immunization Activity template</xsl:comment>
            <primarySource value="false"/>
            <!-- TODO: Add performer -->
            
            <xsl:apply-templates select="doseQuantity" mode="immunization"/>
            <xsl:if test="cda:performer">
                <practitioner>
                    <xsl:call-template name="performer-reference">
                        <xsl:with-param name="element-name">actor</xsl:with-param>
                    </xsl:call-template>
                </practitioner>
            </xsl:if>
        </Immunization>
    </xsl:template>
    
    <!-- CDA IPS IPS Immunization
        https://art-decor.org/ad/#/hl7ips-/rules/templates/2.16.840.1.113883.10.22.4.15/2024-08-04T21:20:24
    -->
    <xsl:template match="cda:substanceAdministration[cda:templateId/@root='2.16.840.1.113883.10.22.4.15'][@moodCode='EVN']" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry"/>
    </xsl:template>
    <xsl:template match="cda:substanceAdministration[cda:templateId/@root='2.16.840.1.113883.10.22.4.15'][@moodCode='EVN']">
        <Immunization>
            <xsl:call-template name="add-meta"/>
            <xsl:apply-templates select="cda:id"/>
            
            <!-- CDA IPS statusCode Fixed: @code = completed  -->
            <status value="completed"/>
            
            <xsl:apply-templates select="cda:consumable" mode="immunization"/>
            
            <xsl:call-template name="subject-reference">
                <xsl:with-param name="element-name">patient</xsl:with-param>
            </xsl:call-template>
            
            <xsl:apply-templates select="cda:effectiveTime" mode="instant">
                <xsl:with-param name="elementName">occurrenceDateTime</xsl:with-param>
            </xsl:apply-templates>      
            
            <xsl:apply-templates select="cda:entryRelationship/cda:observation/cda:value" mode="immunization"/>

        </Immunization>
    </xsl:template>
    
    <xsl:template match="cda:value" mode="immunization">
        <doseQuantity>
            <xsl:if test="@value">
                <value value="{@value}"/>
            </xsl:if>
            <xsl:if test="@unit">
                <unit value="{@unit}"/>
            </xsl:if>
            <xsl:if test="@nullFlavor">
                <code value="{@nullFlavor}"/>
                <system value="http://hl7.org/fhir/v3/NullFlavor"/>
            </xsl:if>
        </doseQuantity>
    </xsl:template>
    
    <xsl:template match="cda:consumable" mode="immunization">
        <xsl:for-each select="cda:manufacturedProduct/cda:manufacturedMaterial/cda:code[@code][@codeSystem]">
            <xsl:call-template name="newCreateCodableConcept">
                <xsl:with-param name="elementName">vaccineCode</xsl:with-param>
            </xsl:call-template>
        </xsl:for-each>
        <!--
        <vaccineCode>
            <xsl:for-each select="cda:manufacturedProduct/cda:manufacturedMaterial/cda:code[@code][@codeSystem]">
                <coding>
                    <system>
                    	<xsl:attribute name="value">
                    		<xsl:call-template name="convertOID">
                    			<xsl:with-param name="oid" select="@codeSystem"/>
                    		</xsl:call-template>
                    	</xsl:attribute>
                    </system>
                    <code value="{@code}"/>
                    <xsl:if test="@displayName">
                    	<display value="{@displayName}"/>
                    </xsl:if>
                </coding>
            </xsl:for-each>
            <xsl:for-each select="cda:manufacturedProduct/cda:manufacturedMaterial/cda:code/cda:translation[@code][@codeSystem]">
                <coding>
                    <system>
                    	<xsl:attribute name="value">
                    		<xsl:call-template name="convertOID">
                    			<xsl:with-param name="oid" select="@codeSystem"/>
                    		</xsl:call-template>
                    	</xsl:attribute>
                    </system>
                    <code value="{@code}"/>
                    <xsl:if test="@displayName">
                    	<display value="{@displayName}"/>
                    </xsl:if>
                </coding>
            </xsl:for-each>
        </vaccineCode>
        -->
    </xsl:template>
    
</xsl:stylesheet>